import { act, fireEvent, render, within } from '@testing-library/react-native';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { UseSmileIDSampleResultCard, UseSmileIDSampleResultLine } from '../src/components/use-smile-id-sample-result-card';
import {
  smileIDSampleResultDefaults,
  smileIDSampleResultFields,
  smileIDSampleResultSelecting,
  type UseSmileIDSampleRunContext,
} from '../src/model/use-smile-id-sample-result';
import { useSmileIDSampleResultStore } from '../src/state/use-smile-id-sample-result-store';
import { UseSmileIDSampleThemeProvider } from '../src/theme/use-smile-id-sample-theme';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';

const run: UseSmileIDSampleRunContext = {
  scenario: 'normal',
  theme: 'brandDefault',
  route: 'fullscreen',
  environment: 'production',
};

const store = () => useSmileIDSampleResultStore.getState();

beforeEach(() => store().reset());

describe('the counts', () => {
  it('start at zero for every run, not once per launch', () => {
    store().start(run);
    store().record('cancelled');
    store().refreshed();
    store().start({ ...run, environment: 'sandbox' });
    expect(store().result).toMatchObject({
      jobStatus: 'running',
      resultCallbackCount: 0,
      refreshCallbackCount: 0,
      environment: 'sandbox',
    });
  });

  it('count a second delivery rather than absorbing it', () => {
    store().start(run);
    store().record('succeeded', { jobId: 'job-1' });
    store().record('cancelled');
    expect(store().result).toMatchObject({ resultCallbackCount: 2, jobStatus: 'cancelled', jobId: null });
  });

  it('a refresh keeps the recorded job', () => {
    store().start(run);
    store().record('succeeded', { jobId: 'job-1', userId: 'user-1' });
    store().refreshed();
    expect(store().result).toMatchObject({ refreshCallbackCount: 1, jobId: 'job-1', userId: 'user-1' });
  });

  it('a run the gate blocked failed, but no callback fired', () => {
    store().block('Missing partner icon', run);
    expect(store().result).toMatchObject({
      jobStatus: 'failed',
      resultCallbackCount: 0,
      lastError: 'Missing partner icon',
    });
  });

  it('the launch selection moves an idle card and leaves a recorded run alone', () => {
    expect(smileIDSampleResultSelecting(smileIDSampleResultDefaults, 'badRefresh', 'brandDefault').activeScenario).toBe(
      'badRefresh',
    );
    store().start(run);
    expect(smileIDSampleResultSelecting(store().result, 'badRefresh', 'brandDefault').activeScenario).toBe('normal');
  });
});

describe('the tree', () => {
  const inTheme = (element: React.ReactElement) =>
    render(<UseSmileIDSampleThemeProvider dark={false}>{element}</UseSmileIDSampleThemeProvider>);

  it('publishes every schema field under its spec id', async () => {
    const schema = JSON.parse(readFileSync(join(__dirname, '../../../spec/result-card.schema.json'), 'utf8')) as {
      properties: Record<string, unknown>;
    };
    expect(smileIDSampleResultFields.map((entry) => entry.field).sort()).toEqual(Object.keys(schema.properties).sort());
    const screen = await inTheme(<UseSmileIDSampleResultCard result={smileIDSampleResultDefaults} />);
    const card = within(screen.getByTestId(UseSmileIDSampleTestIds.RESULT_CARD));
    for (const { testId } of smileIDSampleResultFields) expect(card.getByTestId(testId)).toBeTruthy();
  });

  it('an absent value renders as a dash, not as nothing', async () => {
    const screen = await inTheme(<UseSmileIDSampleResultCard result={smileIDSampleResultDefaults} />);
    expect(screen.getByTestId(UseSmileIDSampleTestIds.RESULT_JOB_ID).props.children).toBe('—');
  });

  it('collapsing hides the fields and keeps the card', async () => {
    const screen = await inTheme(<UseSmileIDSampleResultCard result={smileIDSampleResultDefaults} />);
    await act(async () => {
      fireEvent.press(screen.getByText('Hide'));
    });
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.RESULT_JOB_STATUS)).toBeNull();
    expect(screen.getByTestId(UseSmileIDSampleTestIds.RESULT_CARD)).toBeTruthy();
  });

  it('the compact line carries status, scenario and route only', async () => {
    const screen = await inTheme(
      <UseSmileIDSampleResultLine result={{ ...smileIDSampleResultDefaults, jobStatus: 'running' }} />,
    );
    for (const id of [
      UseSmileIDSampleTestIds.RESULT_JOB_STATUS,
      UseSmileIDSampleTestIds.RESULT_ACTIVE_SCENARIO,
      UseSmileIDSampleTestIds.RESULT_ROUTE,
    ]) {
      expect(screen.getByTestId(id)).toBeTruthy();
    }
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.RESULT_ENVIRONMENT)).toBeNull();
  });
});
