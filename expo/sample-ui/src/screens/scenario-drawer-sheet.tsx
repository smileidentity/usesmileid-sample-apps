import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import { smileIDSampleScenarios, smileIDSampleThemeScenarios } from '../model/use-smile-id-sample-scenario';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  /// The active flow scenario's id.
  scenario: string;
  /// The active theme scenario's id.
  theme: string;
  onScenarioSelect: (scenario: string) => void;
  onThemeSelect: (theme: string) => void;
  onDismiss: () => void;
};

/// The flow and theme scenarios, both shown at once because a run carries one of each.
export const ScenarioDrawerSheet = ({ scenario, theme, onScenarioSelect, onThemeSelect, onDismiss }: Props) => (
  <UseSmileIDSampleBottomSheet
    title="Scenarios"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.SCENARIO_DRAWER}
  >
    <UseSmileIDSampleSectionLabel text="FLOW" />
    {smileIDSampleScenarios.map((option) => (
      <UseSmileIDSampleOptionRow
        key={option.id}
        label={option.label}
        selected={option.id === scenario}
        onPress={() => onScenarioSelect(option.id)}
        testID={UseSmileIDSampleSuffixedTestIds.scenarioItem(option.id)}
      />
    ))}
    <UseSmileIDSampleSectionLabel text="THEME" />
    {smileIDSampleThemeScenarios.map((option) => (
      <UseSmileIDSampleOptionRow
        key={option.id}
        label={option.label}
        selected={option.id === theme}
        onPress={() => onThemeSelect(option.id)}
        testID={UseSmileIDSampleSuffixedTestIds.themeItem(option.id)}
      />
    ))}
  </UseSmileIDSampleBottomSheet>
);
