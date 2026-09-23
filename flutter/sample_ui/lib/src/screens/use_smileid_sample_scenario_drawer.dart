import 'package:flutter/material.dart';

import '../components/use_smileid_sample_option_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../model/use_smileid_sample_scenario.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// The flow and theme scenarios, as a sheet over whatever asked for it.
class UseSmileIDSampleScenarioDrawer extends StatelessWidget {
  /// Both selections are shown at once, because a run carries one of each.
  const UseSmileIDSampleScenarioDrawer({
    required this.scenario,
    required this.theme,
    required this.onScenarioSelected,
    required this.onThemeSelected,
    super.key,
  });

  /// The active flow scenario.
  final UseSmileIDSampleScenario scenario;

  /// The active theme scenario.
  final UseSmileIDSampleThemeScenario theme;

  /// Chooses a flow scenario.
  final ValueChanged<UseSmileIDSampleScenario> onScenarioSelected;

  /// Chooses a theme scenario.
  final ValueChanged<UseSmileIDSampleThemeScenario> onThemeSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const UseSmileIDSampleSectionLabel(text: 'FLOW'),
      const SizedBox(height: SmileDimens.spacingSm),
      for (final UseSmileIDSampleScenario option
          in UseSmileIDSampleScenario.values)
        UseSmileIDSampleOptionRow(
          label: option.label,
          selected: option == scenario,
          onTap: () => onScenarioSelected(option),
          testId: UseSmileIDSampleTestIds.scenarioItem(option.id),
        ),
      const SizedBox(height: SmileDimens.spacingSm),
      const UseSmileIDSampleSectionLabel(text: 'THEME'),
      const SizedBox(height: SmileDimens.spacingSm),
      for (final UseSmileIDSampleThemeScenario option
          in UseSmileIDSampleThemeScenario.values)
        UseSmileIDSampleOptionRow(
          label: option.label,
          selected: option == theme,
          onTap: () => onThemeSelected(option),
          testId: UseSmileIDSampleTestIds.themeItem(option.id),
        ),
    ],
  );
}
