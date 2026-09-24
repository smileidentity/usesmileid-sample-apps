import 'dart:async';

import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The profiles store that survives a restart, beside the settings in the same preferences.
class UseSmileIDSamplePreferencesProfilesRepository
    implements UseSmileIDSampleProfilesRepository {
  /// Takes the already-opened preferences, so a caller cannot forget to await them.
  UseSmileIDSamplePreferencesProfilesRepository(this._preferences);

  final SharedPreferences _preferences;

  /// Serialises the writes, so the last change is the one that lands.
  Future<void> _writes = Future<void>.value();

  /// Opens the store, which is done once before the first frame.
  static Future<UseSmileIDSamplePreferencesProfilesRepository> open() async =>
      UseSmileIDSamplePreferencesProfilesRepository(
        await SharedPreferences.getInstance(),
      );

  @override
  UseSmileIDSampleProfiles read() {
    try {
      return UseSmileIDSampleProfilesCodec.decode(
        _preferences.getString(useSmileIDSampleProfilesKey),
      );
    } on Object {
      // A value of another type under the key reads as no profiles, never a crash.
      return UseSmileIDSampleProfiles();
    }
  }

  @override
  Future<void> write(UseSmileIDSampleProfiles profiles) {
    final String encoded = UseSmileIDSampleProfilesCodec.encode(profiles);
    return _writes = _writes.then((_) async {
      try {
        await _preferences.setString(useSmileIDSampleProfilesKey, encoded);
      } on Object {
        // The platform store can refuse a write; the next change tries again with the whole record.
      }
    });
  }
}
