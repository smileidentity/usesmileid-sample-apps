import 'dart:async';
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
  ///
  /// Not const: the write queue below is per-store mutable state, and every caller reaches this
  /// through [open] rather than constructing a constant.
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

  /// Serialises the writes below. A read-modify-write with an await in the middle loses an update
  /// when two switches are tapped before the first write lands: both read the same base and the
  /// second write carries the first's old value. Six undebounced switches make that easy to hit.
  Future<void> _writes = Future<void>.value();

  @override
  Future<UseSmileIDSampleSettings> setSetting(
    UseSmileIDSampleSetting setting,
    bool enabled,
  ) {
    final Completer<UseSmileIDSampleSettings> done =
        Completer<UseSmileIDSampleSettings>();
    _writes = _writes.then((_) async {
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
    }).catchError((Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }
}
