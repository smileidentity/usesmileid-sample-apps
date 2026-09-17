import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings store that survives a restart.
///
/// It lives in the shell rather than in `sample_ui` because the plugin is a platform binding, and
/// the package runs under eight hosts that may each keep their settings somewhere else. The keys
/// are the four apps' shared set, so one device carries one set of preferences rather than four.
class UseSmileIDSamplePreferencesSettingsRepository
    implements UseSmileIDSampleSettingsRepository {
  /// Takes the already-opened preferences, so a caller cannot forget to await them.
  const UseSmileIDSamplePreferencesSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  /// Opens the store, which is done once before the first frame.
  static Future<UseSmileIDSamplePreferencesSettingsRepository> open() async =>
      UseSmileIDSamplePreferencesSettingsRepository(
        await SharedPreferences.getInstance(),
      );

  @override
  Future<UseSmileIDSampleSettings> read() async {
    const UseSmileIDSampleSettings defaults = UseSmileIDSampleSettings();
    bool stored(String key, bool fallback) =>
        _preferences.getBool(key) ?? fallback;
    // Normalised on the way OUT, not only on the way in: a store written by an older build, or by
    // hand, can hold the pair the SDK refuses, and the screen must never be handed it.
    return UseSmileIDSampleSettings(
      enhancedSmartSelfie: stored(
        UseSmileIDSampleSettingsKeys.enhancedSmartSelfie,
        defaults.enhancedSmartSelfie,
      ),
      agentMode: stored(
        UseSmileIDSampleSettingsKeys.agentMode,
        defaults.agentMode,
      ),
      darkMode: stored(
        UseSmileIDSampleSettingsKeys.darkMode,
        defaults.darkMode,
      ),
      consentStep: stored(
        UseSmileIDSampleSettingsKeys.consentStep,
        defaults.consentStep,
      ),
      instructionsStep: stored(
        UseSmileIDSampleSettingsKeys.instructionsStep,
        defaults.instructionsStep,
      ),
      previewStep: stored(
        UseSmileIDSampleSettingsKeys.previewStep,
        defaults.previewStep,
      ),
    ).normalised();
  }

  @override
  Future<UseSmileIDSampleSettings> setSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  ) async {
    // Through the model, so the capture mutex can move the OTHER switch, and both are then written.
    final UseSmileIDSampleSettings updated = (await read()).withSetting(
      setting,
      enabled,
    );
    for (final UseSmileIDSampleSetting each in UseSmileIDSampleSetting.values) {
      await _preferences.setBool(
        UseSmileIDSampleSettingsKeys.of(each),
        updated[each],
      );
    }
    return updated;
  }
}
