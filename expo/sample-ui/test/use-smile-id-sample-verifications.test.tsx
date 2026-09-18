import { fireEvent } from '@testing-library/react-native';

import { smileIDSampleJobFixtures } from '../src/data/use-smile-id-sample-job-fixtures';
import {
  smileIDSampleGroupByDay,
  smileIDSampleStartOfDay,
  smileIDSampleTimeLabels,
} from '../src/model/use-smile-id-sample-job-dates';
import { smileIDSampleHttpLabel } from '../src/model/use-smile-id-sample-job';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { VerificationDetailsScreen } from '../src/screens/verification-details-screen';
import {
  VerificationsScreen,
  smileIDSampleFilterCounts,
} from '../src/screens/verifications-screen';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { renderInTheme, schemes, styleTree } from './render-in-theme';

const noop = () => {};

/// A fixed clock, so a day header never depends on when the suite runs.
const NOW = new Date('2026-07-16T13:03:41.000Z').getTime();
const fixtures = smileIDSampleJobFixtures(NOW);

const list = (
  overrides: Partial<Parameters<typeof VerificationsScreen>[0]> = {},
): React.ReactElement => (
  <VerificationsScreen
    state={{ jobs: fixtures, nowMillis: NOW }}
    onJobPress={noop}
    onRemove={noop}
    {...overrides}
  />
);

const details = (
  overrides: Partial<Parameters<typeof VerificationDetailsScreen>[0]> = {},
): React.ReactElement => (
  <VerificationDetailsScreen
    state={{ job: fixtures[0]!, jobId: fixtures[0]!.id, refreshing: false }}
    onBack={noop}
    onDelete={noop}
    onRefresh={noop}
    onCopy={noop}
    {...overrides}
  />
);

type Case = { element: () => React.ReactElement };

const cases: { screen: string; states: Record<string, Case> }[] = [
  {
    screen: 'verifications',
    states: {
      default: { element: () => list() },
      // Not loaded is not empty, and neither draws the other's message.
      notLoaded: { element: () => list({ state: { jobs: null, nowMillis: NOW } }) },
      empty: { element: () => list({ state: { jobs: [], nowMillis: NOW } }) },
    },
  },
  {
    screen: 'verificationDetails',
    states: {
      // One state per status the design draws, since the badge and the message both move. The
      // default fixture is Clear, so Processing has to be posed with the fixture that is one.
      processing: {
        element: () =>
          details({ state: { job: fixtures[1]!, jobId: fixtures[1]!.id, refreshing: false } }),
      },
      clear: {
        element: () =>
          details({
            state: {
              job: { ...fixtures[0]!, status: UseSmileIDSampleStatus.Clear, message: 'Approved', httpStatus: 200 },
              jobId: fixtures[0]!.id,
              refreshing: false,
            },
          }),
      },
      attention: {
        element: () =>
          details({
            state: {
              job: {
                ...fixtures[0]!,
                status: UseSmileIDSampleStatus.Attention,
                message: 'Provisional — needs review',
                httpStatus: 200,
              },
              jobId: fixtures[0]!.id,
              refreshing: false,
            },
          }),
      },
      blocked: {
        element: () =>
          details({
            state: {
              job: { ...fixtures[0]!, status: UseSmileIDSampleStatus.Blocked, message: 'Rejected', httpStatus: 200 },
              jobId: fixtures[0]!.id,
              refreshing: false,
            },
          }),
      },
      refreshNotice: {
        element: () =>
          details({
            state: {
              job: fixtures[0]!,
              jobId: fixtures[0]!.id,
              refreshing: false,
              refreshNotice: 'Never submitted, so there is nothing to check',
            },
          }),
      },
      // A deep link can name a row this build has no copy of, and the id is the whole diagnostic.
      noRow: {
        element: () => details({ state: { job: null, jobId: 'job_99ky31za00', refreshing: false } }),
      },
    },
  },
];

describe.each(cases)('$screen', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      expect(await styleTree(states[state]!.element(), dark)).toMatchSnapshot();
    });
  });
});

describe('the recording environment', () => {
  it('formats in UTC and en-US, or a baseline would pin the machine that recorded it', () => {
    // Both are set in jest.config.js, before the config is exported.
    const resolved = Intl.DateTimeFormat().resolvedOptions();
    expect(resolved.timeZone).toBe('UTC');
    expect(resolved.locale).toBe('en-US');
  });
});

describe('verifications coverage', () => {
  it('records both schemes for every state', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(18);
  });
});

describe('the filter counts', () => {
  it('are the counts the design draws, which is what a delete is asserted on', () => {
    expect(smileIDSampleFilterCounts(fixtures)).toEqual({
      all: 11,
      clear: 6,
      attention: 2,
      blocked: 2,
    });
  });

  it('drop when a row goes, so the count proves the delete rather than the toast', () => {
    const afterDelete = fixtures.filter((job) => job.status !== UseSmileIDSampleStatus.Blocked);
    expect(smileIDSampleFilterCounts(afterDelete)).toEqual({
      all: 9,
      clear: 6,
      attention: 2,
      blocked: 0,
    });
  });

  it('gives each chip a count node a flow can read by id', async () => {
    const rendered = await renderInTheme(list(), false);
    for (const id of ['all', 'clear', 'attention', 'blocked']) {
      expect(rendered.queryByTestId(`sample_filter_count_${id}`)).not.toBeNull();
    }
  });
});

describe('removing the last row of the active filter', () => {
  it('falls back to All rather than leaving a blank screen under a chip reading 0', async () => {
    const blocked = fixtures.filter((job) => job.status === UseSmileIDSampleStatus.Blocked);
    const removed: string[] = [];
    const rendered = await renderInTheme(
      list({ onRemove: (ids) => removed.push(...ids) }),
      false,
    );
    await fireEvent.press(rendered.getByTestId('sample_filter_chip_blocked'));
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE));
    // Select both blocked rows, then hide them: the filter has nothing left to show.
    for (const job of blocked) {
      const index = fixtures.indexOf(job);
      await fireEvent.press(rendered.getByTestId(`sample_selection_checkbox_${index}`));
    }
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SELECTION_REMOVE));
    expect(removed.sort()).toEqual(blocked.map((job) => job.id).sort());
    // Back on All, so the rows that remain are visible rather than hidden behind an empty filter.
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.VERIFICATIONS_EMPTY)).toBeNull();
  });

  it('runs one shared handler for the swipe and the selection bar', async () => {
    // Two copies of the reset is how only one of them gets a rule added to it.
    const calls: string[][] = [];
    const rendered = await renderInTheme(list({ onRemove: (ids) => calls.push([...ids]) }), false);
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE));
    await fireEvent.press(rendered.getByTestId('sample_selection_checkbox_0'));
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SELECTION_REMOVE));
    expect(calls).toEqual([[fixtures[0]!.id]]);
  });
});

describe('select mode', () => {
  it('replaces the bottom chrome rather than stacking a second bar', async () => {
    const rendered = await renderInTheme(list(), false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.SELECTION_BAR)).toBeNull();
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE));
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.SELECTION_BAR)).not.toBeNull();
  });

  it('turns the header action into Cancel', async () => {
    const rendered = await renderInTheme(list(), false);
    expect(rendered.getByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE)).toHaveTextContent('Select');
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE));
    expect(rendered.getByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE)).toHaveTextContent('Cancel');
  });

  it('offers no select action with nothing to select', async () => {
    const rendered = await renderInTheme(list({ state: { jobs: [], nowMillis: NOW } }), false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.SELECT_TOGGLE)).toBeNull();
  });
});

describe('the empty list', () => {
  it('says nothing submitted yet on a first launch', async () => {
    const rendered = await renderInTheme(list({ state: { jobs: [], nowMillis: NOW } }), false);
    expect(rendered.queryByText('Nothing submitted yet')).not.toBeNull();
    expect(rendered.queryByText('No verifications match this filter')).toBeNull();
  });

  it('says nothing matches when a filter hides everything', async () => {
    const clearOnly = fixtures.filter((job) => job.status === UseSmileIDSampleStatus.Clear);
    const rendered = await renderInTheme(list({ state: { jobs: clearOnly, nowMillis: NOW } }), false);
    await fireEvent.press(rendered.getByTestId('sample_filter_chip_blocked'));
    expect(rendered.queryByText('No verifications match this filter')).not.toBeNull();
    // The two texts share one id, so the wrong one showing is a defect a count cannot catch.
    expect(rendered.queryByText('Nothing submitted yet')).toBeNull();
  });

  it('draws neither message before the store has read', async () => {
    const rendered = await renderInTheme(list({ state: { jobs: null, nowMillis: NOW } }), false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.VERIFICATIONS_EMPTY)).toBeNull();
  });
});

describe('the day grouping', () => {
  it('names today and yesterday and leaves older days to their date alone', () => {
    const days = smileIDSampleGroupByDay(
      [
        { ...fixtures[0]!, id: 'today', createdAtMillis: NOW },
        { ...fixtures[0]!, id: 'yesterday', createdAtMillis: NOW - 24 * 60 * 60 * 1000 },
        { ...fixtures[0]!, id: 'older', createdAtMillis: NOW - 5 * 24 * 60 * 60 * 1000 },
      ],
      NOW,
      'en-GB',
    );
    expect(days.map((day) => day.relative)).toEqual(['TODAY', 'YESTERDAY', '']);
  });

  it('formats the absolute date rather than hardcoding one', () => {
    const [day] = smileIDSampleGroupByDay([fixtures[0]!], NOW, 'en-GB');
    expect(day?.absolute).toMatch(/^[A-Z]{3}, \d{2} [A-Z]{3} \d{4}$/);
  });

  it('buckets by calendar day, so two rows hours apart can still share a header', () => {
    const start = smileIDSampleStartOfDay(NOW);
    const days = smileIDSampleGroupByDay(
      [
        { ...fixtures[0]!, id: 'a', createdAtMillis: start + 1000 },
        { ...fixtures[0]!, id: 'b', createdAtMillis: start + 20 * 60 * 60 * 1000 },
      ],
      NOW,
      'en-GB',
    );
    expect(days).toHaveLength(1);
  });

  it('labels each row with a wall-clock time from one formatter', () => {
    const labels = smileIDSampleTimeLabels([fixtures[0]!], 'en-GB');
    expect(labels[fixtures[0]!.id]).toMatch(/^\d{2}:\d{2}:\d{2}$/);
  });
});

describe('the details screen', () => {
  it('composes the reason phrase where the row is drawn', () => {
    expect(smileIDSampleHttpLabel(200)).toBe('200 OK');
    expect(smileIDSampleHttpLabel(202)).toBe('202 Accepted');
    expect(smileIDSampleHttpLabel(null)).toBeNull();
    // An unknown code still reads as a code rather than as nothing.
    expect(smileIDSampleHttpLabel(418)).toBe('418');
  });

  it('offers the refresh gesture in every state, not only processing', async () => {
    // A hostless renderer never mounts a RefreshControl, so the wiring is read off the scroll view's
    // own prop rather than looked up by id — the same blind spot as a switch knob, asserted instead.
    for (const status of [
      UseSmileIDSampleStatus.Processing,
      UseSmileIDSampleStatus.Clear,
      UseSmileIDSampleStatus.Blocked,
    ]) {
      const rendered = await renderInTheme(
        details({ state: { job: { ...fixtures[0]!, status }, jobId: 'x', refreshing: false } }),
        false,
      );
      const scroll = rendered.getByTestId(UseSmileIDSampleTestIds.VERIFICATION_DETAILS_SCREEN);
      const control = scroll.props.refreshControl as { props?: { testID?: string } } | undefined;
      expect(control?.props?.testID).toBe(UseSmileIDSampleTestIds.DETAILS_REFRESH);
    }
  });

  it('names the id it could not find, which is the whole diagnostic', async () => {
    const rendered = await renderInTheme(
      details({ state: { job: null, jobId: 'job_99ky31za00', refreshing: false } }),
      false,
    );
    expect(rendered.queryByText('job_99ky31za00')).not.toBeNull();
  });

  it('offers no delete for a row it does not hold', async () => {
    const rendered = await renderInTheme(
      details({ state: { job: null, jobId: 'nope', refreshing: false } }),
      false,
    );
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.DETAILS_DELETE)).toBeNull();
  });

  it('copies the full id, never the truncated one the row shows', async () => {
    const copied: string[] = [];
    const rendered = await renderInTheme(
      details({ onCopy: (_field, value) => copied.push(value) }),
      false,
    );
    await fireEvent.press(rendered.getByTestId('sample_detail_copy_jobId'));
    expect(copied).toEqual([fixtures[0]!.id]);
  });

  it('publishes the environment, which only this screen and the result card do', async () => {
    const rendered = await renderInTheme(details(), false);
    expect(rendered.queryByText('sandbox')).not.toBeNull();
  });
});
