import 'package:flutter/foundation.dart';

import '../use_smileid_sample_strings.dart';
import '../use_smileid_sample_test_ids.dart';

/// Which settings row a toggle belongs to, so a caller can name one without naming every field.
enum UseSmileIDSampleSetting {
  /// ON is the head-turn challenge, and it fights agent mode.
  enhancedSmartSelfie(UseSmileIDSampleTestIds.settingEnhancedSmartSelfie),

  /// ON lets an operator capture for the applicant, and it fights enhanced liveness.
  agentMode(UseSmileIDSampleTestIds.settingAgentMode),

  /// Includes or omits `consent()` in the flow.
  consentStep(UseSmileIDSampleTestIds.settingConsentStep),

  /// Includes or omits `instructions()`.
  instructionsStep(UseSmileIDSampleTestIds.settingInstructionsStep),

  /// Includes or omits `preview()`.
  previewStep(UseSmileIDSampleTestIds.settingPreviewStep),

  /// DocumentCaptureConfig.allowGalleryUpload; off, as the SDK defaults it.
  galleryUpload(UseSmileIDSampleTestIds.settingGalleryUpload),

  /// DocumentCaptureConfig.allowSkipBack; off, as the SDK defaults it.
  allowSkipBack(UseSmileIDSampleTestIds.settingAllowSkipBack),

  /// The document products capture the selfie before the document.
  selfieFirst(UseSmileIDSampleTestIds.settingSelfieFirst);

  const UseSmileIDSampleSetting(this.testId);

  /// The `sample_*` id the row carries, which is spec data rather than the screen's choice.
  final String testId;
}

/// DocumentCaptureConfig.captureMode, in `spec/test-ids.json`'s vocabulary.
enum UseSmileIDSampleCaptureMode {
  /// Captures when the document is held steady.
  auto('auto'),

  /// The shutter shows at once.
  manual('manual'),

  /// Automatic, with the shutter after the SDK's 10 seconds.
  autoWithFallback('autoWithFallback');

  const UseSmileIDSampleCaptureMode(this.id);

  /// The id that suffixes this row's test id and is what the store keeps.
  final String id;

  /// What the row and the Settings line say.
  String label(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleCaptureMode.auto => strings.captureModeAuto,
    UseSmileIDSampleCaptureMode.manual => strings.captureModeManual,
    UseSmileIDSampleCaptureMode.autoWithFallback =>
      strings.captureModeAutoWithFallback,
  };
}

/// The app's theme choice; System follows the device's own theme.
enum UseSmileIDSampleAppearance {
  /// Follows the device.
  system('system'),

  /// Always light.
  light('light'),

  /// Always dark.
  dark('dark');

  const UseSmileIDSampleAppearance(this.id);

  /// The id that suffixes this row's test id and is what the store keeps.
  final String id;

  /// Whether the app renders dark, given the device's own theme.
  bool isDark({required bool deviceDark}) => switch (this) {
    UseSmileIDSampleAppearance.system => deviceDark,
    UseSmileIDSampleAppearance.light => false,
    UseSmileIDSampleAppearance.dark => true,
  };

  /// System names the device's theme, never the one the app renders, so the row says why it looks as it does.
  String label(UseSmileIDSampleStrings strings, {required bool deviceDark}) =>
      switch (this) {
        UseSmileIDSampleAppearance.system =>
          deviceDark
              ? strings.appearanceSystemDark
              : strings.appearanceSystemLight,
        UseSmileIDSampleAppearance.light => strings.appearanceLight,
        UseSmileIDSampleAppearance.dark => strings.appearanceDark,
      };
}

/// The app's language: System follows the device; the rest are in `spec/l10n/languages.json`.
enum UseSmileIDSampleLanguage {
  /// Follows the device.
  system('system', ''),

  /// English.
  en('en', 'English'),

  /// French.
  fr('fr', 'Français'),

  /// Arabic, right to left.
  ar('ar', 'العربية'),

  /// Hebrew, right to left.
  he('he', 'עברית');

  const UseSmileIDSampleLanguage(this.id, this.endonym);

  /// The id that suffixes this row's test id and is what the store keeps.
  final String id;

  /// The language's name in itself, which no other language translates.
  final String endonym;

  /// Whether the language reads right to left.
  bool get rightToLeft => this == ar || this == he;

  /// System resolves to the first device language the app ships, else English.
  UseSmileIDSampleLanguage resolved(List<String> deviceLanguages) =>
      this != system
      ? this
      : deviceLanguages
                .map(shipped)
                .whereType<UseSmileIDSampleLanguage>()
                .firstOrNull ??
            en;

  /// System names the language the device resolves to; a named language is its own endonym.
  String label(UseSmileIDSampleStrings strings, List<String> deviceLanguages) =>
      this == system
      ? strings.languageSystem(language: resolved(deviceLanguages).endonym)
      : endonym;

  /// The shipped language a BCP 47 tag names, by its language subtag; Android still reports Hebrew as `iw`.
  static UseSmileIDSampleLanguage? shipped(String tag) {
    final String language = tag.split(RegExp('[-_]')).first.toLowerCase();
    final String id = language == 'iw' ? 'he' : language;
    return values
        .where((UseSmileIDSampleLanguage l) => l != system && l.id == id)
        .firstOrNull;
  }
}

/// The Settings state. Three of these decide whether a step is composed into the SDK flow at all.
@immutable
class UseSmileIDSampleSettings {
  /// Enhanced SmartSelfie is ON by default, which is the state the design draws.
  const UseSmileIDSampleSettings({
    this.enhancedSmartSelfie = true,
    this.agentMode = false,
    this.consentStep = true,
    this.instructionsStep = true,
    this.previewStep = true,
    this.galleryUpload = false,
    this.allowSkipBack = false,
    this.selfieFirst = false,
    this.captureMode = UseSmileIDSampleCaptureMode.autoWithFallback,
    this.appearance = UseSmileIDSampleAppearance.system,
    this.language = UseSmileIDSampleLanguage.system,
  });

  /// The head-turn challenge.
  final bool enhancedSmartSelfie;

  /// Operator capture.
  final bool agentMode;

  /// Whether the flow includes the SDK's consent step.
  final bool consentStep;

  /// Whether the flow includes the SDK's instructions step.
  final bool instructionsStep;

  /// Whether the flow includes the SDK's preview step.
  final bool previewStep;

  /// Whether the SDK offers the gallery on document capture.
  final bool galleryUpload;

  /// Whether the back-side capture offers Skip.
  final bool allowSkipBack;

  /// Whether the document products capture the selfie first.
  final bool selfieFirst;

  /// A typed field rather than one of the switches: three values, not two.
  final UseSmileIDSampleCaptureMode captureMode;

  /// Typed like [captureMode]; System follows the device.
  final UseSmileIDSampleAppearance appearance;

  /// Typed like [appearance]; System follows the device's own language.
  final UseSmileIDSampleLanguage language;

  /// Reads one row, so a caller can diff two states without naming every field.
  bool operator [](UseSmileIDSampleSetting setting) => switch (setting) {
    UseSmileIDSampleSetting.enhancedSmartSelfie => enhancedSmartSelfie,
    UseSmileIDSampleSetting.agentMode => agentMode,
    UseSmileIDSampleSetting.consentStep => consentStep,
    UseSmileIDSampleSetting.instructionsStep => instructionsStep,
    UseSmileIDSampleSetting.previewStep => previewStep,
    UseSmileIDSampleSetting.galleryUpload => galleryUpload,
    UseSmileIDSampleSetting.allowSkipBack => allowSkipBack,
    UseSmileIDSampleSetting.selfieFirst => selfieFirst,
  };

  /// Drops enhanced liveness where a stored state carries both, so the SDK is never handed the pair.
  UseSmileIDSampleSettings normalised() => agentMode && enhancedSmartSelfie
      ? _copy(enhancedSmartSelfie: false)
      : this;

  /// The capture mutex: the SDK refuses agent mode with enhanced liveness, so turning either on
  /// turns the other off. Here rather than on the screen, because both persistence paths inherit it.
  UseSmileIDSampleSettings withSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  ) => switch (setting) {
    UseSmileIDSampleSetting.enhancedSmartSelfie => _copy(
      enhancedSmartSelfie: enabled,
      agentMode: agentMode && !enabled,
    ),
    UseSmileIDSampleSetting.agentMode => _copy(
      agentMode: enabled,
      enhancedSmartSelfie: enhancedSmartSelfie && !enabled,
    ),
    UseSmileIDSampleSetting.consentStep => _copy(consentStep: enabled),
    UseSmileIDSampleSetting.instructionsStep => _copy(
      instructionsStep: enabled,
    ),
    UseSmileIDSampleSetting.previewStep => _copy(previewStep: enabled),
    UseSmileIDSampleSetting.galleryUpload => _copy(galleryUpload: enabled),
    UseSmileIDSampleSetting.allowSkipBack => _copy(allowSkipBack: enabled),
    UseSmileIDSampleSetting.selfieFirst => _copy(selfieFirst: enabled),
  };

  /// A copy with [captureMode] chosen.
  UseSmileIDSampleSettings withCaptureMode(
    UseSmileIDSampleCaptureMode captureMode,
  ) => _copy(captureMode: captureMode);

  /// A copy with [appearance] chosen.
  UseSmileIDSampleSettings withAppearance(
    UseSmileIDSampleAppearance appearance,
  ) => _copy(appearance: appearance);

  /// A copy with [language] chosen.
  UseSmileIDSampleSettings withLanguage(UseSmileIDSampleLanguage language) =>
      _copy(language: language);

  UseSmileIDSampleSettings _copy({
    bool? enhancedSmartSelfie,
    bool? agentMode,
    bool? consentStep,
    bool? instructionsStep,
    bool? previewStep,
    bool? galleryUpload,
    bool? allowSkipBack,
    bool? selfieFirst,
    UseSmileIDSampleCaptureMode? captureMode,
    UseSmileIDSampleAppearance? appearance,
    UseSmileIDSampleLanguage? language,
  }) => UseSmileIDSampleSettings(
    enhancedSmartSelfie: enhancedSmartSelfie ?? this.enhancedSmartSelfie,
    agentMode: agentMode ?? this.agentMode,
    consentStep: consentStep ?? this.consentStep,
    instructionsStep: instructionsStep ?? this.instructionsStep,
    previewStep: previewStep ?? this.previewStep,
    galleryUpload: galleryUpload ?? this.galleryUpload,
    allowSkipBack: allowSkipBack ?? this.allowSkipBack,
    selfieFirst: selfieFirst ?? this.selfieFirst,
    captureMode: captureMode ?? this.captureMode,
    appearance: appearance ?? this.appearance,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleSettings &&
      other.enhancedSmartSelfie == enhancedSmartSelfie &&
      other.agentMode == agentMode &&
      other.consentStep == consentStep &&
      other.instructionsStep == instructionsStep &&
      other.previewStep == previewStep &&
      other.galleryUpload == galleryUpload &&
      other.allowSkipBack == allowSkipBack &&
      other.selfieFirst == selfieFirst &&
      other.captureMode == captureMode &&
      other.appearance == appearance &&
      other.language == language;

  @override
  int get hashCode => Object.hash(
    enhancedSmartSelfie,
    agentMode,
    consentStep,
    instructionsStep,
    previewStep,
    galleryUpload,
    allowSkipBack,
    selfieFirst,
    captureMode,
    appearance,
    language,
  );
}
