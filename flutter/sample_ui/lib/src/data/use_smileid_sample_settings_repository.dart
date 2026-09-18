import '../state/use_smileid_sample_settings.dart';

/// Where the six switches are kept, so the screen never knows what is doing the keeping.
abstract interface class UseSmileIDSampleSettingsRepository {
  /// The stored settings, or the plain defaults on a first launch.
  Future<UseSmileIDSampleSettings> read();

  /// Applies one switch and returns what was stored, which the capture mutex may have altered.
  Future<UseSmileIDSampleSettings> setSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  );
}

/// The keys the store writes, shared across all four apps so a device carries one set, not four.
abstract final class UseSmileIDSampleSettingsKeys {
  /// The head-turn challenge, under a NEW key: `smile_to_capture = true` meant the opposite, so a
  /// reused key would read every upgraded install backwards.
  static const String enhancedSmartSelfie = 'enhanced_smart_selfie';

  /// Operator capture.
  static const String agentMode = 'agent_mode';

  /// The app's dark appearance.
  static const String darkMode = 'dark_mode';

  /// Whether the flow includes the SDK's consent step.
  static const String consentStep = 'consent_step';

  /// Whether the flow includes the SDK's instructions step.
  static const String instructionsStep = 'instructions_step';

  /// Whether the flow includes the SDK's preview step.
  static const String previewStep = 'preview_step';

  /// The key one switch is stored under.
  static String of(UseSmileIDSampleSetting setting) => switch (setting) {
    UseSmileIDSampleSetting.enhancedSmartSelfie => enhancedSmartSelfie,
    UseSmileIDSampleSetting.agentMode => agentMode,
    UseSmileIDSampleSetting.darkMode => darkMode,
    UseSmileIDSampleSetting.consentStep => consentStep,
    UseSmileIDSampleSetting.instructionsStep => instructionsStep,
    UseSmileIDSampleSetting.previewStep => previewStep,
  };
}

/// Settings that live as long as the process, which is what a test and a preview want.
class UseSmileIDSampleMemorySettingsRepository
    implements UseSmileIDSampleSettingsRepository {
  /// [initial] is normalised on the way in, so no caller can seed the pair the SDK refuses.
  UseSmileIDSampleMemorySettingsRepository([
    UseSmileIDSampleSettings initial = const UseSmileIDSampleSettings(),
  ]) : _settings = initial.normalised();

  UseSmileIDSampleSettings _settings;

  @override
  Future<UseSmileIDSampleSettings> read() async => _settings;

  @override
  Future<UseSmileIDSampleSettings> setSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  ) async => _settings = _settings.withSetting(setting, enabled);
}
