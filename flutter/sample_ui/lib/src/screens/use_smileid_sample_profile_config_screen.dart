import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_key_value_edit_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../state/use_smileid_sample_profiles.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// One profile's own page: its four user details, and the act that makes it active.
///
/// The title is the PROFILE'S NAME rather than a static heading, so a reader who arrived by deep
/// link knows which profile they are editing.
class UseSmileIDSampleProfileConfigScreen extends StatelessWidget {
  /// [isActive] disables the only write on the page, which is what the twin does.
  const UseSmileIDSampleProfileConfigScreen({
    required this.organisation,
    required this.details,
    required this.isActive,
    required this.onBack,
    required this.onFieldChanged,
    required this.onSave,
    super.key,
  });

  /// The profile's organisation, which is also the page's title.
  final String organisation;

  /// The details as edited so far; the page holds none of its own.
  final UseSmileIDSampleUserDetails details;

  /// Whether this profile is already active.
  final bool isActive;

  /// Leaves the page, discarding anything unsaved.
  final VoidCallback onBack;

  /// Called on every keystroke, so the owner holds the edit.
  final void Function(UseSmileIDSampleUserField field, String value)
  onFieldChanged;

  /// Saves the details AND makes this profile active; the two are one act.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.profileConfigScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(title: organisation, onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              children: <Widget>[
                const UseSmileIDSampleSectionLabel(
                  text: 'USER DETAILS — ATTACHED TO EVERY JOB',
                ),
                const SizedBox(height: SmileDimens.spacingSm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: UseSmileIDSampleShapes.card,
                    border: Border.all(
                      color: colors.cardStroke,
                      width: smileCardStrokeWidth,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: UseSmileIDSampleShapes.card,
                    child: Column(
                      children: <Widget>[
                        for (
                          int i = 0;
                          i < UseSmileIDSampleUserField.values.length;
                          i++
                        ) ...<Widget>[
                          if (i > 0) const UseSmileIDSampleSettingRowDivider(),
                          UseSmileIDSampleKeyValueEditRow(
                            label: UseSmileIDSampleUserField.values[i].label,
                            value: UseSmileIDSampleUserField.values[i].valueOf(
                              details,
                            ),
                            onChanged: (String value) => onFieldChanged(
                              UseSmileIDSampleUserField.values[i],
                              value,
                            ),
                            placeholder:
                                UseSmileIDSampleUserField.values[i].placeholder,
                            required:
                                UseSmileIDSampleUserField.values[i].isRequired,
                            testId: UseSmileIDSampleTestIds.profileConfigField(
                              UseSmileIDSampleUserField.values[i].id,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pinned rather than scrolled: the page's only write must not be below a fold.
          Padding(
            padding: const EdgeInsets.all(SmileDimens.spacingMd),
            child: UseSmileIDSampleButton(
              text: isActive ? 'Active profile' : 'Make this profile active',
              onPressed: onSave,
              enabled: !isActive,
              testId: UseSmileIDSampleTestIds.profileConfigSave,
            ),
          ),
        ],
      ),
    );
  }
}
