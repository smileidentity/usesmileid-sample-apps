import '../state/use_smileid_sample_settings.dart';

/// Where the settings are kept, so the screen never knows what is doing the keeping.
abstract interface class UseSmileIDSampleSettingsRepository {
  /// The stored settings, or the plain defaults on a first launch.
  Future<UseSmileIDSampleSettings> read();

  /// Applies one switch and returns what was stored, which the capture mutex may have altered.
  Future<UseSmileIDSampleSettings> setSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  );

  /// Stores the capture mode and returns what was stored.
  Future<UseSmileIDSampleSettings> setCaptureMode(
    UseSmileIDSampleCaptureMode mode,
  );

  /// Stores the appearance and returns what was stored.
  Future<UseSmileIDSampleSettings> setAppearance(
    UseSmileIDSampleAppearance appearance,
  );

  /// Stores the language and returns what was stored.
  Future<UseSmileIDSampleSettings> setLanguage(
    UseSmileIDSampleLanguage language,
  );
}

/// The keys the store writes, shared across all four apps so a device carries one set, not four.
abstract final class UseSmileIDSampleSettingsKeys {
  /// The head-turn challenge, under a NEW key: `smile_to_capture = true` meant the opposite, so a
  /// reused key would read every upgraded install backwards.
  static const String enhancedSmartSelfie = 'enhanced_smart_selfie';

  /// Operator capture.
  static const String agentMode = 'agent_mode';

  /// The Dark mode switch that [appearance] replaced, read only to carry an installed choice over.
  static const String darkMode = 'dark_mode';

  /// Whether the flow includes the SDK's consent step.
  static const String consentStep = 'consent_step';

  /// Whether the flow includes the SDK's instructions step.
  static const String instructionsStep = 'instructions_step';

  /// Whether the flow includes the SDK's preview step.
  static const String previewStep = 'preview_step';

  /// Whether the SDK offers the gallery on document capture.
  static const String galleryUpload = 'gallery_upload';

  /// Whether the back-side capture offers Skip.
  static const String allowSkipBack = 'allow_skip_back';

  /// Whether the document products capture the selfie first.
  static const String selfieFirst = 'selfie_first';

  /// The capture mode, stored by its id.
  static const String captureMode = 'capture_mode';

  /// The appearance, stored by its id.
  static const String appearance = 'appearance';

  /// The language, stored by its id.
  static const String language = 'language';

  /// The key one switch is stored under.
  static String of(UseSmileIDSampleSetting setting) => switch (setting) {
    UseSmileIDSampleSetting.enhancedSmartSelfie => enhancedSmartSelfie,
    UseSmileIDSampleSetting.agentMode => agentMode,
    UseSmileIDSampleSetting.consentStep => consentStep,
    UseSmileIDSampleSetting.instructionsStep => instructionsStep,
    UseSmileIDSampleSetting.previewStep => previewStep,
    UseSmileIDSampleSetting.galleryUpload => galleryUpload,
    UseSmileIDSampleSetting.allowSkipBack => allowSkipBack,
    UseSmileIDSampleSetting.selfieFirst => selfieFirst,
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

  @override
  Future<UseSmileIDSampleSettings> setCaptureMode(
    UseSmileIDSampleCaptureMode mode,
  ) async => _settings = _settings.withCaptureMode(mode);

  @override
  Future<UseSmileIDSampleSettings> setAppearance(
    UseSmileIDSampleAppearance appearance,
  ) async => _settings = _settings.withAppearance(appearance);

  @override
  Future<UseSmileIDSampleSettings> setLanguage(
    UseSmileIDSampleLanguage language,
  ) async => _settings = _settings.withLanguage(language);
}
