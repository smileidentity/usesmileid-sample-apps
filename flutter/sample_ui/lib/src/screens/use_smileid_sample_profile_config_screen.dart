import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_confirm_dialog.dart';
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

/// One profile's own page: its organisation, four user details and callback URL, and one CTA that
/// saves the active profile's edits or saves and activates any other.
class UseSmileIDSampleProfileConfigScreen extends StatelessWidget {
  /// [changed] is all the active profile's Save can act on.
  const UseSmileIDSampleProfileConfigScreen({
    required this.organisation,
    required this.details,
    required this.isActive,
    required this.onBack,
    required this.onFieldChanged,
    required this.onSave,
    this.title,
    this.onOrganisationChanged,
    this.changed = false,
    this.onDelete,
    this.callbackUrl = '',
    this.onCallbackUrlChanged,
    this.callbackOverride,
    super.key,
  });

  /// The organisation as edited so far, which the SDK's consent screen names as the partner.
  final String organisation;

  /// The page's title: the saved profile's, so it does not change as the name is typed.
  final String? title;

  /// Called on every keystroke in the organisation row.
  final ValueChanged<String>? onOrganisationChanged;

  /// Whether anything differs from what is stored.
  final bool changed;

  /// Deletes the profile once confirmed; null hides the row.
  final VoidCallback? onDelete;

  /// The details as edited so far; the page holds none of its own.
  final UseSmileIDSampleUserDetails details;

  /// Whether this profile is already active.
  final bool isActive;

  /// Leaves the page, discarding anything unsaved.
  final VoidCallback onBack;

  /// Called on every keystroke, so the owner holds the edit.
  final void Function(UseSmileIDSampleUserField field, String value)
  onFieldChanged;

  /// Saves the edits, and makes this profile active when it is not already.
  final VoidCallback onSave;

  /// The webhook URL as edited so far; empty means the partner's portal default.
  final String callbackUrl;

  /// Called on every keystroke in the callback URL row.
  final ValueChanged<String>? onCallbackUrlChanged;

  /// Non-null while a token session is live: its text replaces the value, and the row stops editing.
  final String? callbackOverride;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.profileConfigScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(
            title: title ?? organisation,
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              children: <Widget>[
                const UseSmileIDSampleSectionLabel(text: 'PROFILE'),
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
                    child: UseSmileIDSampleKeyValueEditRow(
                      label: 'Organisation',
                      value: organisation,
                      onChanged: onOrganisationChanged ?? (String _) {},
                      placeholder: 'Shown on the consent screen',
                      testId: UseSmileIDSampleTestIds.profileConfigName,
                    ),
                  ),
                ),
                const SizedBox(height: SmileDimens.spacingSm),
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
                const SizedBox(height: SmileDimens.spacingSm),
                // Its own section, not a row in the card above: a webhook URL is not a user detail.
                const UseSmileIDSampleSectionLabel(text: 'CALLBACK URL'),
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
                    child: UseSmileIDSampleKeyValueEditRow(
                      label: 'Webhook URL',
                      value: callbackOverride == null ? callbackUrl : '',
                      onChanged: onCallbackUrlChanged ?? (String _) {},
                      placeholder:
                          callbackOverride ?? 'Uses your portal default',
                      enabled: callbackOverride == null,
                      keyboardType: TextInputType.url,
                      testId: UseSmileIDSampleTestIds.profileConfigCallbackUrl,
                    ),
                  ),
                ),
                if (onDelete != null) ...<Widget>[
                  const SizedBox(height: SmileDimens.spacingSm),
                  UseSmileIDSampleDestructiveRow(
                    text: 'Delete profile',
                    onTap: () async {
                      if (await showUseSmileIDSampleConfirmation(
                        context,
                        title: 'Delete ${title ?? organisation}?',
                        message:
                            'Its details and callback URL are removed from this device.',
                        confirmLabel: 'Delete',
                        confirmTestId:
                            UseSmileIDSampleTestIds.profileDeleteConfirm,
                      )) {
                        onDelete!();
                      }
                    },
                    testId: UseSmileIDSampleTestIds.profileConfigDelete,
                  ),
                ],
              ],
            ),
          ),
          // Pinned rather than scrolled: the page's only write must not be below a fold.
          Padding(
            padding: const EdgeInsets.all(SmileDimens.spacingMd),
            child: UseSmileIDSampleButton(
              // One slot, as the design has it: the active profile saves its edits, any other also becomes active.
              text: isActive ? 'Save changes' : 'Use this profile',
              onPressed: onSave,
              enabled: changed || !isActive,
              testId: UseSmileIDSampleTestIds.profileConfigSave,
            ),
          ),
        ],
      ),
    );
  }
}
