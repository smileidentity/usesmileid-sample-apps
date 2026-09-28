import 'package:flutter/foundation.dart';

import '../use_smileid_sample_test_ids.dart';

/// Which settings row a toggle belongs to, so a caller can name one without naming six fields.
enum UseSmileIDSampleSetting {
  /// ON is the head-turn challenge, and it fights agent mode.
  enhancedSmartSelfie(UseSmileIDSampleTestIds.settingEnhancedSmartSelfie),

  /// ON lets an operator capture for the applicant, and it fights enhanced liveness.
  agentMode(UseSmileIDSampleTestIds.settingAgentMode),

  /// The app's own appearance; the SDK follows the host.
  darkMode(UseSmileIDSampleTestIds.settingDarkMode),

  /// Includes or omits `consent()` in the flow.
  consentStep(UseSmileIDSampleTestIds.settingConsentStep),

  /// Includes or omits `instructions()`.
  instructionsStep(UseSmileIDSampleTestIds.settingInstructionsStep),

  /// Includes or omits `preview()`.
  previewStep(UseSmileIDSampleTestIds.settingPreviewStep);

  const UseSmileIDSampleSetting(this.testId);

  /// The `sample_*` id the row carries, which is spec data rather than the screen's choice.
  final String testId;
}

/// The Settings state. Three of these decide whether a step is composed into the SDK flow at all.
@immutable
class UseSmileIDSampleSettings {
  /// Enhanced SmartSelfie is ON by default, which is the state the design draws.
  const UseSmileIDSampleSettings({
    this.enhancedSmartSelfie = true,
    this.agentMode = false,
    this.darkMode = false,
    this.consentStep = true,
    this.instructionsStep = true,
    this.previewStep = true,
  });

  /// The head-turn challenge.
  final bool enhancedSmartSelfie;

  /// Operator capture.
  final bool agentMode;

  /// The app's dark appearance.
  final bool darkMode;

  /// Whether the flow includes the SDK's consent step.
  final bool consentStep;

  /// Whether the flow includes the SDK's instructions step.
  final bool instructionsStep;

  /// Whether the flow includes the SDK's preview step.
  final bool previewStep;

  /// Reads one row, so a caller can diff two states without naming six fields.
  bool operator [](UseSmileIDSampleSetting setting) => switch (setting) {
    UseSmileIDSampleSetting.enhancedSmartSelfie => enhancedSmartSelfie,
    UseSmileIDSampleSetting.agentMode => agentMode,
    UseSmileIDSampleSetting.darkMode => darkMode,
    UseSmileIDSampleSetting.consentStep => consentStep,
    UseSmileIDSampleSetting.instructionsStep => instructionsStep,
    UseSmileIDSampleSetting.previewStep => previewStep,
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
    UseSmileIDSampleSetting.darkMode => _copy(darkMode: enabled),
    UseSmileIDSampleSetting.consentStep => _copy(consentStep: enabled),
    UseSmileIDSampleSetting.instructionsStep => _copy(
      instructionsStep: enabled,
    ),
    UseSmileIDSampleSetting.previewStep => _copy(previewStep: enabled),
  };

  UseSmileIDSampleSettings _copy({
    bool? enhancedSmartSelfie,
    bool? agentMode,
    bool? darkMode,
    bool? consentStep,
    bool? instructionsStep,
    bool? previewStep,
  }) => UseSmileIDSampleSettings(
    enhancedSmartSelfie: enhancedSmartSelfie ?? this.enhancedSmartSelfie,
    agentMode: agentMode ?? this.agentMode,
    darkMode: darkMode ?? this.darkMode,
    consentStep: consentStep ?? this.consentStep,
    instructionsStep: instructionsStep ?? this.instructionsStep,
    previewStep: previewStep ?? this.previewStep,
  );

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleSettings &&
      other.enhancedSmartSelfie == enhancedSmartSelfie &&
      other.agentMode == agentMode &&
      other.darkMode == darkMode &&
      other.consentStep == consentStep &&
      other.instructionsStep == instructionsStep &&
      other.previewStep == previewStep;

  @override
  int get hashCode => Object.hash(
    enhancedSmartSelfie,
    agentMode,
    darkMode,
    consentStep,
    instructionsStep,
    previewStep,
  );
}
