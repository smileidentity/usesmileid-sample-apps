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
      galleryUpload: stored(
        UseSmileIDSampleSettingsKeys.galleryUpload,
        defaults.galleryUpload,
      ),
      allowSkipBack: stored(
        UseSmileIDSampleSettingsKeys.allowSkipBack,
        defaults.allowSkipBack,
      ),
      selfieFirst: stored(
        UseSmileIDSampleSettingsKeys.selfieFirst,
        defaults.selfieFirst,
      ),
      captureMode:
          UseSmileIDSampleCaptureMode.values
              .where(
                (UseSmileIDSampleCaptureMode mode) =>
                    mode.id ==
                    _preferences.getString(
                      UseSmileIDSampleSettingsKeys.captureMode,
                    ),
              )
              .firstOrNull ??
          defaults.captureMode,
      appearance: _appearance(),
    ).normalised();
  }

  /// A stored id wins; else the legacy switch, where only true proves a choice: this store wrote false on any change.
  UseSmileIDSampleAppearance _appearance() {
    final String? stored = _preferences.getString(
      UseSmileIDSampleSettingsKeys.appearance,
    );
    for (final UseSmileIDSampleAppearance appearance
        in UseSmileIDSampleAppearance.values) {
      if (appearance.id == stored) return appearance;
    }
    return _preferences.getBool(UseSmileIDSampleSettingsKeys.darkMode) == true
        ? UseSmileIDSampleAppearance.dark
        : UseSmileIDSampleAppearance.system;
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

  @override
  Future<UseSmileIDSampleSettings> setCaptureMode(
    UseSmileIDSampleCaptureMode mode,
  ) {
    final Completer<UseSmileIDSampleSettings> done =
        Completer<UseSmileIDSampleSettings>();
    _writes = _writes
        .then((_) async {
          await _preferences.setString(
            UseSmileIDSampleSettingsKeys.captureMode,
            mode.id,
          );
          done.complete(await read());
        })
        .catchError((Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        });
    return done.future;
  }

  /// Two writes, not one transaction; a crash between them is safe because the stored id is read first.
  @override
  Future<UseSmileIDSampleSettings> setAppearance(
    UseSmileIDSampleAppearance appearance,
  ) {
    final Completer<UseSmileIDSampleSettings> done =
        Completer<UseSmileIDSampleSettings>();
    _writes = _writes
        .then((_) async {
          await _preferences.setString(
            UseSmileIDSampleSettingsKeys.appearance,
            appearance.id,
          );
          await _preferences.remove(UseSmileIDSampleSettingsKeys.darkMode);
          done.complete(await read());
        })
        .catchError((Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        });
    return done.future;
  }
}
