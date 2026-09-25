import { Text, View } from 'react-native';

import { UseSmileIDSampleDataFieldRow } from '../src/components/use-smile-id-sample-data-field-row';
import { UseSmileIDSampleDateGroupHeader } from '../src/components/use-smile-id-sample-date-group-header';
import { UseSmileIDSampleEmptyState } from '../src/components/use-smile-id-sample-empty-state';
import { UseSmileIDSampleFilterChip } from '../src/components/use-smile-id-sample-filter-chip';
import { UseSmileIDSampleIcon } from '../src/components/use-smile-id-sample-icon';
import { UseSmileIDSampleJobRow } from '../src/components/use-smile-id-sample-job-row';
import { UseSmileIDSampleKeyValueEditRow } from '../src/components/use-smile-id-sample-key-value-edit-row';
import { UseSmileIDSampleOptionRow } from '../src/components/use-smile-id-sample-option-row';
import { UseSmileIDSampleProfileRow } from '../src/components/use-smile-id-sample-profile-row';
import {
  UseSmileIDSampleResultCard,
  UseSmileIDSampleResultLine,
} from '../src/components/use-smile-id-sample-result-card';
import { smileIDSampleResultDefaults } from '../src/model/use-smile-id-sample-result';
import {
  UseSmileIDSampleRowDivider,
  UseSmileIDSampleSectionSurface,
} from '../src/components/use-smile-id-sample-section-surface';
import { UseSmileIDSampleSelectionBar } from '../src/components/use-smile-id-sample-selection-bar';
import { UseSmileIDSampleSelectionCheckbox } from '../src/components/use-smile-id-sample-selection-checkbox';
import {
  UseSmileIDSampleSelectTrigger,
  UseSmileIDSampleTriggerEmoji,
} from '../src/components/use-smile-id-sample-select-trigger';
import {
  UseSmileIDSampleDestructiveRow,
  UseSmileIDSampleSettingRow,
  UseSmileIDSampleSettingRowChevron,
} from '../src/components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleSwitch } from '../src/components/use-smile-id-sample-switch';
import {
  UseSmileIDSampleTopAppBar,
  UseSmileIDSampleTopAppBarButton,
} from '../src/components/use-smile-id-sample-top-app-bar';
import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { smileLightColors } from '../src/theme/smile-colors';
import { focusField, pressIn, schemes, styleTree, type Interaction } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

const noop = () => {};

/// Ids used only to drive a state that needs an interaction; the screens supply the real ones.
const FIELD_ID = 'golden_field';
const CHIP_ID = 'golden_chip';

/// The same fixtures on every platform, so a pair of goldens can actually be read against each other.
const product = smileIDSampleProducts[0]!;
const documentProduct = smileIDSampleProducts[2]!;

type Case = { element: () => React.ReactElement; interact?: Interaction };

/// Every state each composite declares in spec/components.json, so a missing state has no golden.
const cases: { component: string; states: Record<string, Case> }[] = [
  {
    component: 'SectionSurface',
    states: {
      labelled: {
        element: () => (
          <UseSmileIDSampleSectionSurface label="DETAILS">
            <UseSmileIDSampleDataFieldRow label="Job_id" value="7d2f01aa" />
          </UseSmileIDSampleSectionSurface>
        ),
      },
      unlabelled: {
        element: () => (
          <UseSmileIDSampleSectionSurface>
            <UseSmileIDSampleDataFieldRow label="Job_id" value="7d2f01aa" />
            <UseSmileIDSampleRowDivider />
            <UseSmileIDSampleDataFieldRow label="User_id" value="u-8891" />
          </UseSmileIDSampleSectionSurface>
        ),
      },
    },
  },
  {
    component: 'TopAppBar',
    states: {
      backOnly: { element: () => <UseSmileIDSampleTopAppBar title="User details" onBack={noop} /> },
      backWithDelete: {
        element: () => (
          <UseSmileIDSampleTopAppBar
            title="Verification"
            onBack={noop}
            action={
              <UseSmileIDSampleTopAppBarButton
                accessibilityLabel="Delete"
                onPress={noop}
                emphasis="Destructive"
                glyph={(tint) => <UseSmileIDSampleIcon name="trash" tint={tint} />}
              />
            }
          />
        ),
      },
      backWithTorch: {
        element: () => (
          <UseSmileIDSampleTopAppBar
            title="Scan token"
            onBack={noop}
            action={
              <UseSmileIDSampleTopAppBarButton
                accessibilityLabel="Torch"
                onPress={noop}
                emphasis="Filled"
                glyph={(tint) => <UseSmileIDSampleIcon name="flash" tint={tint} />}
              />
            }
          />
        ),
      },
      // The title wraps rather than ellipsising, which is what the no-clipping predicate forbids.
      wrappingTitle: {
        element: () => (
          <UseSmileIDSampleTopAppBar title="Enhanced Document Verification" onBack={noop} />
        ),
      },
    },
  },
  {
    component: 'DataFieldRow',
    states: {
      plain: { element: () => <UseSmileIDSampleDataFieldRow label="Environment" value="sandbox" /> },
      withCopy: {
        element: () => (
          <UseSmileIDSampleDataFieldRow label="Job_id" value="7d2f01aa-4b1c" onCopy={noop} />
        ),
      },
      withStatusValue: {
        element: () => (
          <UseSmileIDSampleDataFieldRow label="Status" value="202 Accepted" valueColor={smileLightColors.badge.infoText} />
        ),
      },
    },
  },
  {
    component: 'KeyValueEditRow',
    states: {
      empty: {
        element: () => (
          <UseSmileIDSampleKeyValueEditRow
            label="First name"
            value=""
            onValueChange={noop}
            placeholder="Required"
            required
          />
        ),
      },
      filled: {
        element: () => (
          <UseSmileIDSampleKeyValueEditRow label="First name" value="Ada" onValueChange={noop} />
        ),
      },
      focused: {
        element: () => (
          <UseSmileIDSampleKeyValueEditRow
            label="First name"
            value="Ada"
            onValueChange={noop}
            testID={FIELD_ID}
          />
        ),
        interact: focusField(FIELD_ID),
      },
      disabled: {
        element: () => (
          <UseSmileIDSampleKeyValueEditRow
            label="Partner id"
            value="1234"
            onValueChange={noop}
            enabled={false}
          />
        ),
      },
    },
  },
  {
    component: 'SettingRow',
    states: {
      withSwitch: {
        element: () => (
          <UseSmileIDSampleSettingRow
            title="Enhanced SmartSelfie™"
            supportingText="Face capture uses head-turns"
            leading={(tint) => <UseSmileIDSampleIcon name="smile" tint={tint} />}
            trailing={<UseSmileIDSampleSwitch checked onCheckedChange={noop} />}
          />
        ),
      },
      navigation: {
        element: () => (
          <UseSmileIDSampleSettingRow
            title="Documentation"
            onPress={noop}
            leading={(tint) => <UseSmileIDSampleIcon name="docs" tint={tint} />}
            trailing={<UseSmileIDSampleSettingRowChevron />}
          />
        ),
      },
      noSupportingLine: {
        element: () => (
          <UseSmileIDSampleSettingRow
            title="Licenses"
            onPress={noop}
            leading={(tint) => <UseSmileIDSampleIcon name="licenses" tint={tint} />}
            trailing={<UseSmileIDSampleSettingRowChevron />}
          />
        ),
      },
      destructive: { element: () => <UseSmileIDSampleDestructiveRow text="Sign out" onPress={noop} /> },
    },
  },
  {
    component: 'ProfileRow',
    states: {
      default: {
        element: () => (
          <UseSmileIDSampleProfileRow
            organisation="UpTech Finance"
            supportingText="Kwame Asante"
            initials="KA"
            selected={false}
            onPress={noop}
          />
        ),
      },
      selected: {
        element: () => (
          <UseSmileIDSampleProfileRow
            organisation="UpTech Finance"
            supportingText="Kwame Asante"
            initials="KA"
            selected
            onPress={noop}
          />
        ),
      },
      summary: {
        element: () => (
          <UseSmileIDSampleProfileRow
            organisation="No profile yet"
            supportingText="Tap to create one"
            initials=""
            selected={false}
            onPress={noop}
            trailing={<UseSmileIDSampleSettingRowChevron />}
          />
        ),
      },
    },
  },
  {
    component: 'OptionRow',
    states: {
      withLeadingFlag: {
        element: () => (
          <UseSmileIDSampleOptionRow label="Kenya" selected={false} onPress={noop} leadingText="🇰🇪" />
        ),
      },
      plain: { element: () => <UseSmileIDSampleOptionRow label="National ID" selected={false} onPress={noop} /> },
      selected: {
        element: () => (
          <UseSmileIDSampleOptionRow label="Kenya" selected onPress={noop} leadingText="🇰🇪" />
        ),
      },
    },
  },
  {
    component: 'SelectTrigger',
    states: {
      empty: {
        element: () => (
          <UseSmileIDSampleSelectTrigger
            value={null}
            placeholder="Select country"
            onPress={noop}
            leading={() => <UseSmileIDSampleTriggerEmoji emoji="🌍" />}
          />
        ),
      },
      selected: {
        element: () => (
          <UseSmileIDSampleSelectTrigger
            value="Kenya"
            placeholder="Select country"
            onPress={noop}
            leading={() => <UseSmileIDSampleTriggerEmoji emoji="🇰🇪" />}
          />
        ),
      },
      // The ID-type trigger stays greyed until a country is chosen, which is the dependency the spec names.
      disabled: {
        element: () => (
          <UseSmileIDSampleSelectTrigger
            value={null}
            placeholder="Select ID type"
            onPress={noop}
            enabled={false}
          />
        ),
      },
    },
  },
  {
    component: 'FilterChip',
    states: {
      default: {
        element: () => (
          <UseSmileIDSampleFilterChip label="Clear" count={6} selected={false} onPress={noop} />
        ),
      },
      active: {
        element: () => <UseSmileIDSampleFilterChip label="All" count={11} selected onPress={noop} />,
      },
      pressed: {
        element: () => (
          <UseSmileIDSampleFilterChip
            label="Attention"
            count={2}
            selected={false}
            onPress={noop}
            testID={CHIP_ID}
          />
        ),
        interact: pressIn(CHIP_ID),
      },
    },
  },
  {
    component: 'DateGroupHeader',
    states: {
      withRelativeWord: {
        element: () => <UseSmileIDSampleDateGroupHeader relative="TODAY" absolute="THU, 16 JUL 2026" />,
      },
      // A day with no relative word renders the absolute date once, never twice.
      absoluteOnly: {
        element: () => <UseSmileIDSampleDateGroupHeader relative="" absolute="TUE, 14 JUL 2026" />,
      },
    },
  },
  {
    component: 'JobRow',
    states: {
      default: {
        element: () => (
          <UseSmileIDSampleJobRow
            product={product}
            jobId="7d2f01aa…"
            time="13:03:41"
            status={UseSmileIDSampleStatus.Clear}
          />
        ),
      },
      processing: {
        element: () => (
          <UseSmileIDSampleJobRow
            product={documentProduct}
            jobId="91bc4400…"
            time="09:12:07"
            status={UseSmileIDSampleStatus.Processing}
            onPress={noop}
          />
        ),
      },
      blocked: {
        element: () => (
          <UseSmileIDSampleJobRow
            product={documentProduct}
            jobId="44aa1290…"
            time="17:44:02"
            status={UseSmileIDSampleStatus.Blocked}
          />
        ),
      },
    },
  },
  {
    component: 'SelectionCheckbox',
    states: {
      unchecked: { element: () => <UseSmileIDSampleSelectionCheckbox checked={false} onCheckedChange={noop} /> },
      checked: { element: () => <UseSmileIDSampleSelectionCheckbox checked onCheckedChange={noop} /> },
    },
  },
  {
    component: 'SelectionBar',
    states: {
      noneSelected: { element: () => <UseSmileIDSampleSelectionBar selectedCount={0} onRemove={noop} /> },
      someSelected: { element: () => <UseSmileIDSampleSelectionBar selectedCount={3} onRemove={noop} /> },
    },
  },
  {
    component: 'EmptyState',
    states: {
      text: { element: () => <UseSmileIDSampleEmptyState text="No verifications match this filter" /> },
      textWithSupporting: {
        element: () => (
          <UseSmileIDSampleEmptyState
            text="Nothing submitted yet"
            supportingText="Start a verification from the Products tab"
          />
        ),
      },
    },
  },
  {
    // The spec's five states, with the fixtures Android records.
    component: 'ResultCard',
    states: {
      idle: { element: () => <UseSmileIDSampleResultCard result={smileIDSampleResultDefaults} /> },
      running: {
        element: () => (
          <UseSmileIDSampleResultLine result={{ ...smileIDSampleResultDefaults, route: 'shell', jobStatus: 'running' }} />
        ),
      },
      succeeded: {
        element: () => (
          <UseSmileIDSampleResultCard
            result={{
              ...smileIDSampleResultDefaults,
              jobStatus: 'succeeded',
              jobId: 'job_9f3a2c7104e8',
              userId: 'user_5b1ec4d2',
              resultCallbackCount: 1,
            }}
          />
        ),
      },
      cancelled: {
        element: () => (
          <UseSmileIDSampleResultCard
            result={{ ...smileIDSampleResultDefaults, jobStatus: 'cancelled', resultCallbackCount: 1 }}
          />
        ),
      },
      failed: {
        element: () => (
          <UseSmileIDSampleResultCard
            result={{
              ...smileIDSampleResultDefaults,
              activeScenario: 'badRefresh',
              jobStatus: 'failed',
              resultCallbackCount: 1,
              refreshCallbackCount: 2,
              lastError: '2213: authentication failed \u2014 refresh returned an expired token',
            }}
          />
        ),
      },
    },
  },
];

describe.each(cases)('$component', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      const entry = states[state]!;
      await expectGoldens(entry.element(), dark, { interact: entry.interact });
    });
  });
});

describe('composite coverage', () => {
  it('covers every shared composite the buildOrder names, plus the two shared parts', () => {
    expect(cases.map((entry) => entry.component)).toEqual([
      'SectionSurface',
      'TopAppBar',
      'DataFieldRow',
      'KeyValueEditRow',
      'SettingRow',
      'ProfileRow',
      'OptionRow',
      'SelectTrigger',
      'FilterChip',
      'DateGroupHeader',
      'JobRow',
      'SelectionCheckbox',
      'SelectionBar',
      'EmptyState',
      'ResultCard',
    ]);
  });

  it('records both schemes for every state', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(90);
  });

  it('uses one fixture set, so a pair of platforms can be read against each other', () => {
    // Where two platforms' goldens draw different data, no amount of looking tells you if they agree.
    expect([product.id, documentProduct.id]).toEqual(['smartSelfieEnrollment', 'documentVerification']);
  });
});

describe('the shared row divider', () => {
  it('takes the card stroke rather than the mode-invariant color.border', async () => {
    const light = JSON.stringify(await styleTree(<UseSmileIDSampleRowDivider />, false));
    const dark = JSON.stringify(await styleTree(<UseSmileIDSampleRowDivider />, true));
    // color.border is the same near-white in both schemes; the divider must not be.
    expect(light).not.toEqual(dark);
  });
});

describe('a composite with no call site is a defect', () => {
  it('draws the trigger emoji, which only the pickers pass', async () => {
    const tree = await styleTree(
      <View>
        <UseSmileIDSampleTriggerEmoji emoji="🇰🇪" />
        <Text>anchor</Text>
      </View>,
      false,
    );
    expect(JSON.stringify(tree)).toContain('🇰🇪');
  });
});
