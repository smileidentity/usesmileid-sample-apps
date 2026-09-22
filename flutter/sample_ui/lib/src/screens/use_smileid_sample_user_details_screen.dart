import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_key_value_edit_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_switch.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../state/use_smileid_sample_profiles.dart';
import '../state/use_smileid_sample_user_details_requirement.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// The details every product collects before its flow starts. It opens EMPTY even for a profile
/// with saved defaults, as the twin does; whether it should is an open product question.
class UseSmileIDSampleUserDetailsScreen extends StatelessWidget {
  /// [requirement] is what a token has not already covered; its default asks for everything.
  const UseSmileIDSampleUserDetailsScreen({
    required this.title,
    required this.details,
    required this.onBack,
    required this.onFieldChanged,
    required this.onContinue,
    this.requirement = const UseSmileIDSampleUserDetailsRequirement(),
    this.remember = false,
    this.onRememberChanged,
    super.key,
  });

  /// The product's own label, so a reader knows which flow they are entering.
  final String title;

  /// What has been typed so far.
  final UseSmileIDSampleUserDetails details;

  /// Leaves the form.
  final VoidCallback onBack;

  /// Called on every keystroke.
  final void Function(UseSmileIDSampleUserField field, String value)
  onFieldChanged;

  /// Moves to the next step, which is the ID form or the flow itself.
  final VoidCallback onContinue;

  /// What is still outstanding.
  final UseSmileIDSampleUserDetailsRequirement requirement;

  /// Whether the remember switch is on; it persists nothing today.
  final bool remember;

  /// Toggles that switch.
  final ValueChanged<bool>? onRememberChanged;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final bool satisfied = requirement.isSatisfiedBy(details);
    return Semantics(
      identifier: UseSmileIDSampleTestIds.userDetailsScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(title: title, onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              children: <Widget>[
                const UseSmileIDSampleSectionLabel(text: 'YOUR DETAILS'),
                const SizedBox(height: SmileDimens.spacingXs),
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
                            label: requirement.labelFor(
                              UseSmileIDSampleUserField.values[i],
                            ),
                            value: UseSmileIDSampleUserField.values[i].valueOf(
                              details,
                            ),
                            onChanged: (String value) => onFieldChanged(
                              UseSmileIDSampleUserField.values[i],
                              value,
                            ),
                            placeholder:
                                UseSmileIDSampleUserField.values[i].placeholder,
                            testId: UseSmileIDSampleTestIds.userDetailsField(
                              UseSmileIDSampleUserField.values[i].id,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: SmileDimens.spacingXs),
                Semantics(
                  identifier: UseSmileIDSampleTestIds.userDetailsHint,
                  child: Text(
                    // What is OUTSTANDING, which depends on what has been typed and not only on
                    // what the requirement asks: a satisfied form has nothing left to name.
                    satisfied ? 'Tap any field to edit.' : requirement.prompt,
                    style: UseSmileIDSampleType.textStyleCaption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ),
                // Offered only once the form is satisfied, which is the same predicate Continue
                // uses: there is nothing to remember until there is something complete.
                if (satisfied) ...<Widget>[
                  const SizedBox(height: SmileDimens.spacingXs),
                  _RememberCard(
                    remember: remember,
                    onChanged: onRememberChanged,
                    colors: colors,
                  ),
                ],
                const SizedBox(
                  height: SmileDimens.spacingXs + SmileDimens.spacingLg,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SmileDimens.spacingMd),
            child: UseSmileIDSampleButton(
              text: 'Continue',
              onPressed: onContinue,
              enabled: satisfied,
              testId: UseSmileIDSampleTestIds.userDetailsContinue,
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of text beside a switch; deliberately not a SettingRow, which draws a taller row.
class _RememberCard extends StatelessWidget {
  const _RememberCard({
    required this.remember,
    required this.onChanged,
    required this.colors,
  });

  final bool remember;
  final ValueChanged<bool>? onChanged;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: UseSmileIDSampleShapes.card,
      border: Border.all(color: colors.cardStroke, width: smileCardStrokeWidth),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        SmileDimens.spacingMd,
        SmileDimens.spacingSm,
        SmileDimens.spacingSm,
        SmileDimens.spacingSm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Remember these details for next time',
              style: UseSmileIDSampleType.textStyleSubtitle.copyWith(
                fontSize: _rememberTextSize,
                color: colors.textBody,
              ),
            ),
          ),
          const SizedBox(width: SmileDimens.spacingSm),
          UseSmileIDSampleSwitch(
            value: remember,
            onChanged: onChanged,
            testId: UseSmileIDSampleTestIds.rememberDetailsSwitch,
          ),
        ],
      ),
    ),
  );
}

/// The remember line's run, the edit rows' size rather than body's.
const double _rememberTextSize = 13.5;
