import 'dart:async';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings store that survives a restart.
class UseSmileIDSamplePreferencesSettingsRepository
    implements UseSmileIDSampleSettingsRepository {
  /// Takes the already-opened preferences, so a caller cannot forget to await them.
  UseSmileIDSamplePreferencesSettingsRepository(this._preferences);

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

  /// Serialises the writes below.
  Future<void> _writes = Future<void>.value();

  @override
  Future<UseSmileIDSampleSettings> setSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  ) {
    final Completer<UseSmileIDSampleSettings> done =
        Completer<UseSmileIDSampleSettings>();
    _writes = _writes
        .then((_) async {
          // Through the model, so the capture mutex can move the OTHER switch, and both are written.
          final UseSmileIDSampleSettings updated = (await read()).withSetting(
            setting,
            enabled,
          );
          for (final UseSmileIDSampleSetting each
              in UseSmileIDSampleSetting.values) {
            await _preferences.setBool(
              UseSmileIDSampleSettingsKeys.of(each),
              updated[each],
            );
          }
          done.complete(updated);
          // Never rethrown into the chain: one failed write must not stop every later one.
        })
        .catchError((Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        });
    return done.future;
  }
}
