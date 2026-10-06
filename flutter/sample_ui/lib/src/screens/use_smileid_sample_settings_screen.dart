import 'package:flutter/material.dart';

import '../components/use_smileid_sample_confirm_dialog.dart';
import '../components/use_smileid_sample_icon.dart';
import '../components/use_smileid_sample_profile_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_spaced.dart';
import '../components/use_smileid_sample_switch.dart';
import '../state/use_smileid_sample_settings.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_marks.dart';
import '../use_smileid_sample_strings.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// One ABOUT or LEGAL row: an id, a title, the line beneath it, and where it goes.
@immutable
class UseSmileIDSampleNavRow {
  /// A null [url] means the app handles the row itself, which only the licences row does.
  const UseSmileIDSampleNavRow({
    required this.id,
    required this.title,
    required this.icon,
    this.supportingText,
    this.url,
    this.opensInApp = true,
  });

  /// The row's stable id, which suffixes its test id.
  final String id;

  /// The row's title.
  final String title;

  /// The row's mark, from the shared record.
  final String icon;

  /// The line beneath the title, where the design draws one.
  final String? supportingText;

  /// Where the row goes; null means this app renders the destination.
  final String? url;

  /// False for a destination the in-app browser cannot render.
  final bool opensInApp;
}

/// The ABOUT rows, in the order the design draws them.
List<UseSmileIDSampleNavRow> useSmileIDSampleAboutRows(
  UseSmileIDSampleStrings strings,
) => <UseSmileIDSampleNavRow>[
  UseSmileIDSampleNavRow(
    id: 'documentation',
    title: strings.settingsDocumentation,
    supportingText: 'docs.usesmileid.com',
    icon: SmileIcons.docs,
    url: 'https://docs.usesmileid.com/',
  ),
  UseSmileIDSampleNavRow(
    id: 'support',
    title: strings.settingsSupport,
    supportingText: strings.settingsSupportBody,
    icon: SmileIcons.support,
    url: 'https://smile.id/contact-us',
  ),
];

/// The LEGAL rows, in the order the design draws them.
List<UseSmileIDSampleNavRow> useSmileIDSampleLegalRows(
  UseSmileIDSampleStrings strings,
) => <UseSmileIDSampleNavRow>[
  UseSmileIDSampleNavRow(
    id: 'terms',
    title: strings.settingsTerms,
    icon: SmileIcons.terms,
    url: 'https://smile.id/terms-and-conditions',
    opensInApp: false,
  ),
  UseSmileIDSampleNavRow(
    id: 'privacy',
    title: strings.settingsPrivacy,
    icon: SmileIcons.privacy,
    url: 'https://smile.id/privacy-policy',
    opensInApp: false,
  ),
  // No url: Apache-2.0 §4 asks the notice to travel with the distribution, so it is a screen here.
  UseSmileIDSampleNavRow(
    id: 'licenses',
    title: strings.settingsLicenses,
    icon: SmileIcons.licenses,
  ),
];

/// Every navigation row, so a caller can assert the set rather than the screen.
List<UseSmileIDSampleNavRow> useSmileIDSampleNavRows(
  UseSmileIDSampleStrings strings,
) => <UseSmileIDSampleNavRow>[
  ...useSmileIDSampleAboutRows(strings),
  ...useSmileIDSampleLegalRows(strings),
];

/// Everything the settings list renders; callbacks stay parameters, like every screen.
@immutable
class UseSmileIDSampleSettingsState {
  /// [versionLabel] is passed in because it names the host, and this package runs under eight.
  const UseSmileIDSampleSettingsState({
    required this.settings,
    required this.organisation,
    required this.initials,
    required this.versionLabel,
    this.consentBoundByToken = false,
    this.avatarColor,
    this.hasProfile = true,
    required this.deviceDark,
  });

  /// The switches and the capture mode.
  final UseSmileIDSampleSettings settings;

  /// The active profile's organisation.
  final String organisation;

  /// The active profile's initials.
  final String initials;

  /// The footer's app name and version.
  final String versionLabel;

  /// The token has taken the consent decision away, so the switch stops claiming to own it.
  final bool consentBoundByToken;

  /// The active profile's hue, by list position; the first when the caller has no position.
  final Color? avatarColor;

  /// False while there is no profile, when the card invites creating one.
  final bool hasProfile;

  /// The device's own theme, which the System label names; the shell reads it where the app's choice cannot mask it.
  final bool deviceDark;
}

/// Settings, which every other screen's configuration comes from.
class UseSmileIDSampleSettingsScreen extends StatelessWidget {
  /// A null [onOpenScenarioDrawer] hides the DEBUG section: this package may not read a host's
  /// build configuration, so the host decides whether the row exists.
  const UseSmileIDSampleSettingsScreen({
    required this.state,
    required this.onSettingChanged,
    required this.onProfileTap,
    required this.onNavRowTap,
    required this.onSignOut,
    required this.onCaptureModeTap,
    required this.onAppearanceTap,
    required this.onLanguageTap,
    this.onOpenScenarioDrawer,
    this.bottomInset = 0,
    super.key,
  });

  /// What to render.
  final UseSmileIDSampleSettingsState state;

  /// Toggles one row; the mutex is applied where the change is persisted, not here.
  final void Function(UseSmileIDSampleSetting setting, bool enabled)
  onSettingChanged;

  /// Opens the profiles LIST, not the active profile's own page.
  final VoidCallback onProfileTap;

  /// Opens an ABOUT or LEGAL destination.
  final void Function(UseSmileIDSampleNavRow row) onNavRowTap;

  /// Signs out.
  final VoidCallback onSignOut;

  /// Opens the capture-mode sheet.
  final VoidCallback onCaptureModeTap;

  /// Opens the appearance sheet.
  final VoidCallback onAppearanceTap;

  /// Opens the language sheet.
  final VoidCallback onLanguageTap;

  /// Opens the scenario drawer; null hides the DEBUG section entirely.
  final VoidCallback? onOpenScenarioDrawer;

  /// Trailing room so the last row can scroll clear of the floating bar.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.settingsScreen,
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomInset),
        children: useSmileIDSampleSpaced(<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
              vertical: SmileDimens.spacingXs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                context.strings.settingsTitle,
                style: UseSmileIDSampleType.textStyleHeadingPage.copyWith(
                  color: colors.textTitle,
                ),
              ),
            ),
          ),
          _Section(
            label: context.strings.settingsSectionProfile,
            children: <Widget>[
              UseSmileIDSampleProfileRow(
                organisation: state.organisation,
                supportingText: state.hasProfile
                    ? context.strings.settingsProfileConfigure
                    : context.strings.settingsProfileCreate,
                initials: state.initials,
                selected: false,
                onTap: onProfileTap,
                avatarColor: state.avatarColor ?? smileProfileHues.first,
                trailing: const UseSmileIDSampleSettingRowChevron(),
                testId: UseSmileIDSampleTestIds.profileSummary,
              ),
            ],
          ),
          // Mutually exclusive, so each row says what turning it on does to the other.
          _Section(
            label: context.strings.settingsSectionCapture,
            children: <Widget>[
              _switchRow(
                title: _enhancedSmartSelfieTitle,
                icon: SmileIcons.smile,
                supportingText: state.settings.agentMode
                    ? context.strings.settingsEnhancedSmartSelfieMutex
                    : context.strings.settingsEnhancedSmartSelfieBody,
                setting: UseSmileIDSampleSetting.enhancedSmartSelfie,
              ),
              const UseSmileIDSampleSettingRowDivider(),
              _switchRow(
                title: context.strings.settingsAgentMode,
                icon: SmileIcons.agent,
                supportingText: state.settings.enhancedSmartSelfie
                    ? context.strings.settingsAgentModeMutex(
                        setting: _enhancedSmartSelfieTitle,
                      )
                    : context.strings.settingsAgentModeBody,
                setting: UseSmileIDSampleSetting.agentMode,
              ),
            ],
          ),
          _Section(
            label: context.strings.settingsSectionAppearance,
            children: <Widget>[
              UseSmileIDSampleSettingRow(
                title: context.strings.settingsTheme,
                supportingText: state.settings.appearance.label(
                  context.strings,
                  deviceDark: state.deviceDark,
                ),
                onTap: onAppearanceTap,
                leading: (Color tint) => UseSmileIDSampleIcon(
                  asset: SmileIcons.darkMode,
                  tint: tint,
                ),
                trailing: const UseSmileIDSampleSettingRowChevron(),
                testId: UseSmileIDSampleTestIds.settingAppearance,
              ),
            ],
          ),
          _Section(
            label: context.strings.settingsSectionLanguage,
            children: <Widget>[
              UseSmileIDSampleSettingRow(
                title: context.strings.settingsLanguage,
                supportingText: state.settings.language.label(
                  context.strings,
                  UseSmileIDSampleStringsScope.deviceLanguagesOf(context),
                ),
                onTap: onLanguageTap,
                leading: (Color tint) => UseSmileIDSampleIcon(
                  asset: SmileIcons.materialSettingLanguage,
                  tint: tint,
                ),
                trailing: const UseSmileIDSampleSettingRowChevron(),
                testId: UseSmileIDSampleTestIds.settingLanguage,
              ),
            ],
          ),
          _Section(
            label: context.strings.settingsSectionSdkScreens,
            children: <Widget>[
              _switchRow(
                title: context.strings.settingsConsent,
                icon: SmileIcons.consent,
                supportingText: state.consentBoundByToken
                    ? context.strings.settingsConsentBound
                    : context.strings.settingsConsentBody,
                setting: UseSmileIDSampleSetting.consentStep,
              ),
              const UseSmileIDSampleSettingRowDivider(),
              _switchRow(
                title: context.strings.settingsInstructions,
                icon: SmileIcons.instructions,
                supportingText: context.strings.settingsInstructionsBody,
                setting: UseSmileIDSampleSetting.instructionsStep,
              ),
              const UseSmileIDSampleSettingRowDivider(),
              _switchRow(
                title: context.strings.settingsPreview,
                icon: SmileIcons.preview,
                supportingText: context.strings.settingsPreviewBody,
                setting: UseSmileIDSampleSetting.previewStep,
              ),
            ],
          ),
          // The design draws no such section either; it sits with the other capture choices.
          _Section(
            label: context.strings.settingsSectionDocumentCapture,
            children: <Widget>[
              UseSmileIDSampleSettingRow(
                title: context.strings.settingsCaptureMode,
                supportingText: state.settings.captureMode.label(
                  context.strings,
                ),
                onTap: onCaptureModeTap,
                leading: (Color tint) => UseSmileIDSampleIcon(
                  asset: SmileIcons.documentVerification,
                  tint: tint,
                ),
                trailing: const UseSmileIDSampleSettingRowChevron(),
                testId: UseSmileIDSampleTestIds.settingCaptureMode,
              ),
              const UseSmileIDSampleSettingRowDivider(),
              _switchRow(
                title: context.strings.settingsGalleryUpload,
                icon: SmileIcons.preview,
                supportingText: context.strings.settingsGalleryUploadBody,
                setting: UseSmileIDSampleSetting.galleryUpload,
              ),
              const UseSmileIDSampleSettingRowDivider(),
              _switchRow(
                title: context.strings.settingsSkipBack,
                icon: SmileIcons.instructions,
                supportingText: context.strings.settingsSkipBackBody,
                setting: UseSmileIDSampleSetting.allowSkipBack,
              ),
              const UseSmileIDSampleSettingRowDivider(),
              _switchRow(
                title: context.strings.settingsSelfieFirst,
                icon: SmileIcons.smile,
                supportingText: context.strings.settingsSelfieFirstBody,
                setting: UseSmileIDSampleSetting.selfieFirst,
              ),
            ],
          ),
          if (onOpenScenarioDrawer != null)
            _Section(
              label: 'DEBUG',
              children: <Widget>[
                UseSmileIDSampleSettingRow(
                  title: 'Scenarios',
                  supportingText: 'Choose how the environment misbehaves',
                  onTap: onOpenScenarioDrawer,
                  leading: (Color tint) => UseSmileIDSampleIcon(
                    asset: SmileIcons.materialSettingScenarios,
                    tint: tint,
                  ),
                  trailing: const UseSmileIDSampleSettingRowChevron(),
                  testId: UseSmileIDSampleTestIds.scenarioDrawerButton,
                ),
              ],
            ),
          _Section(
            label: context.strings.settingsSectionAbout,
            children: _navRows(useSmileIDSampleAboutRows(context.strings)),
          ),
          _Section(
            label: context.strings.settingsSectionLegal,
            children: _navRows(useSmileIDSampleLegalRows(context.strings)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
            ),
            child: UseSmileIDSampleDestructiveRow(
              text: context.strings.settingsSignOut,
              onTap: () async {
                if (await showUseSmileIDSampleConfirmation(
                  context,
                  title: context.strings.settingsSignOutTitle,
                  message: context.strings.settingsSignOutBody,
                  confirmLabel: context.strings.settingsSignOut,
                  confirmTestId: UseSmileIDSampleTestIds.signOutConfirm,
                )) {
                  onSignOut();
                }
              },
              testId: UseSmileIDSampleTestIds.signOut,
            ),
          ),
          Semantics(
            identifier: UseSmileIDSampleTestIds.versionLabel,
            child: Padding(
              padding: const EdgeInsets.all(SmileDimens.spacingMd),
              child: Text(
                state.versionLabel,
                textAlign: TextAlign.center,
                style: UseSmileIDSampleType.textStyleCaption.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String icon,
    required String supportingText,
    required UseSmileIDSampleSetting setting,
  }) => UseSmileIDSampleSettingRow(
    title: title,
    supportingText: supportingText,
    leading: (Color tint) => UseSmileIDSampleIcon(asset: icon, tint: tint),
    testId: setting.testId,
    trailing: UseSmileIDSampleSwitch(
      value: state.settings[setting],
      onChanged: (bool enabled) => onSettingChanged(setting, enabled),
    ),
  );

  List<Widget> _navRows(List<UseSmileIDSampleNavRow> rows) => <Widget>[
    for (int index = 0; index < rows.length; index++) ...<Widget>[
      if (index > 0) const UseSmileIDSampleSettingRowDivider(),
      UseSmileIDSampleSettingRow(
        title: rows[index].title,
        supportingText: rows[index].supportingText,
        onTap: () => onNavRowTap(rows[index]),
        leading: (Color tint) =>
            UseSmileIDSampleIcon(asset: rows[index].icon, tint: tint),
        trailing: const UseSmileIDSampleSettingRowChevron(),
        testId: '${UseSmileIDSampleTestIds.settingNav}_${rows[index].id}',
      ),
    ],
  ];
}

/// A labelled group in one bordered card, rows separated by a rule rather than by spacing.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SmileDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UseSmileIDSampleSectionLabel(text: label),
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
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark is one constant, so a row that stops carrying it fails a test rather than on a device.
const String _enhancedSmartSelfieTitle =
    'Enhanced ${UseSmileIDSampleMarks.smartSelfie}';
