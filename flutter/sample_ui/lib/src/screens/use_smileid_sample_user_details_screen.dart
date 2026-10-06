import 'package:flutter/material.dart';

import '../components/use_smileid_sample_avatar.dart';
import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_glyphs.dart';
import '../components/use_smileid_sample_key_value_edit_row.dart';
import '../components/use_smileid_sample_profile_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_switch.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../state/use_smileid_sample_contact_rules.dart';
import '../state/use_smileid_sample_profiles.dart';
import '../state/use_smileid_sample_user_details_requirement.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// The details every product collects before its flow starts, filled from the profile the run is for.
class UseSmileIDSampleUserDetailsScreen extends StatelessWidget {
  /// [requirement] is what a token has not already covered; its default asks for everything.
  const UseSmileIDSampleUserDetailsScreen({
    required this.title,
    required this.details,
    required this.onBack,
    required this.onFieldChanged,
    required this.onContinue,
    this.requirement = const UseSmileIDSampleUserDetailsRequirement(),
    this.profile,
    this.profileIndex = 0,
    this.onProfileTap,
    this.saveToProfile = true,
    this.onSaveToProfileChanged,
    this.organisation = '',
    this.onOrganisationChanged,
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

  /// Who this run is for; null while there is no profile, when the form offers to create one.
  final UseSmileIDSampleProfile? profile;

  /// The profile's position, which picks its avatar hue.
  final int profileIndex;

  /// Opens the switch sheet.
  final VoidCallback? onProfileTap;

  /// Whether Continue keeps what was typed: into the profile, or as a new one when there is none.
  final bool saveToProfile;

  /// Toggles that switch.
  final ValueChanged<bool>? onSaveToProfileChanged;

  /// The new profile's name, asked only while there is no profile.
  final String organisation;

  /// Called on every keystroke in the organisation row.
  final ValueChanged<String>? onOrganisationChanged;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final bool satisfied = requirement.isSatisfiedBy(details);
    final UseSmileIDSampleProfile? profile = this.profile;
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
                UseSmileIDSampleProfileRow(
                  organisation:
                      profile?.title(context.strings) ??
                      context.strings.profilesNoProfile,
                  supportingText: profile == null
                      ? context.strings.userDetailsNoProfile
                      : context.strings.userDetailsSwitchProfile,
                  initials: profile?.initials ?? '',
                  selected: false,
                  avatarColor: avatarColorForProfile(profileIndex),
                  onTap: onProfileTap ?? () {},
                  trailing: UseSmileIDSampleGlyphs.chevronDown(
                    colors.textMuted,
                  ),
                  testId: UseSmileIDSampleTestIds.userDetailsProfile,
                ),
                const SizedBox(height: SmileDimens.spacingXs),
                UseSmileIDSampleSectionLabel(
                  text: context.strings.userDetailsSection,
                ),
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
                        if (profile == null) ...<Widget>[
                          UseSmileIDSampleKeyValueEditRow(
                            label: context.strings.userDetailsProfileName,
                            value: organisation,
                            onChanged: onOrganisationChanged ?? (_) {},
                            placeholder:
                                context.strings.userDetailsProfileNameHint,
                            testId: UseSmileIDSampleTestIds.userDetailsField(
                              organisationFieldId,
                            ),
                          ),
                          const UseSmileIDSampleSettingRowDivider(),
                        ],
                        for (
                          int i = 0;
                          i < UseSmileIDSampleUserField.values.length;
                          i++
                        ) ...<Widget>[
                          if (i > 0) const UseSmileIDSampleSettingRowDivider(),
                          // Vaulted, so it cannot be prefilled.
                          UseSmileIDSampleKeyValueEditRow(
                            label: requirement.labelFor(
                              UseSmileIDSampleUserField.values[i],
                              context.strings,
                            ),
                            value:
                                requirement.supplies(
                                  UseSmileIDSampleUserField.values[i],
                                )
                                ? ''
                                : UseSmileIDSampleUserField.values[i].valueOf(
                                    details,
                                  ),
                            onChanged: (String value) => onFieldChanged(
                              UseSmileIDSampleUserField.values[i],
                              value,
                            ),
                            placeholder:
                                requirement.supplies(
                                  UseSmileIDSampleUserField.values[i],
                                )
                                ? context.strings.userDetailsFromToken
                                : UseSmileIDSampleUserField.values[i]
                                      .placeholder(context.strings),
                            enabled: !requirement.supplies(
                              UseSmileIDSampleUserField.values[i],
                            ),
                            keyboardType: UseSmileIDSampleUserField
                                .values[i]
                                .keyboardType,
                            isError:
                                UseSmileIDSampleContactRules.problem(
                                  UseSmileIDSampleUserField.values[i],
                                  UseSmileIDSampleUserField.values[i].valueOf(
                                    details,
                                  ),
                                ) !=
                                null,
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
                    details.contactProblem?.message(context.strings) ??
                        (satisfied
                            ? context.strings.userDetailsEditHint
                            : requirement.prompt(context.strings)),
                    style: UseSmileIDSampleType.textStyleCaption.copyWith(
                      color: details.contactProblem == null
                          ? colors.textMuted
                          : colors.input.borderError,
                    ),
                  ),
                ),
                if (satisfied && details != profile?.defaults) ...<Widget>[
                  const SizedBox(height: SmileDimens.spacingXs),
                  _RememberCard(
                    label: profile == null
                        ? context.strings.userDetailsSaveNew
                        : context.strings.userDetailsSaveTo(
                            profile: profile.title(context.strings),
                          ),
                    remember: saveToProfile,
                    onChanged: onSaveToProfileChanged,
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
              text: context.strings.commonContinue,
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
    required this.label,
    required this.remember,
    required this.onChanged,
    required this.colors,
  });

  final String label;
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
              label,
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

/// The organisation row's id suffix, beside the four user fields'.
const String organisationFieldId = 'organisation';
