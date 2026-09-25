import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The profiles in the Keychain or Keystore, since they hold people's details; read once before the first frame.
class UseSmileIDSampleSecureProfilesRepository
    implements UseSmileIDSampleProfilesRepository {
  UseSmileIDSampleSecureProfilesRepository._(this._storage, this._current);

  final FlutterSecureStorage _storage;

  UseSmileIDSampleProfiles _current;

  /// Serialises the writes, so the last change is the one that lands.
  Future<void> _writes = Future<void>.value();

  /// Reads the stored record, moving a plain one left in the preferences across and deleting it there.
  static Future<UseSmileIDSampleSecureProfilesRepository> open({
    FlutterSecureStorage? storage,
  }) async {
    final FlutterSecureStorage secure =
        storage ?? const FlutterSecureStorage(iOptions: _keychain);
    String? stored;
    try {
      stored = await secure.read(key: useSmileIDSampleProfilesKey);
    } on Object {
      // An unreadable store is no profiles, never a crash on launch.
    }
    if (stored == null) {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final Object? plain = preferences.get(useSmileIDSampleProfilesKey);
      if (plain is String) {
        stored = plain;
        try {
          await secure.write(key: useSmileIDSampleProfilesKey, value: plain);
        } on Object {
          // Kept in memory for this launch; the next change writes it again.
        }
      }
      if (plain != null) {
        await preferences.remove(useSmileIDSampleProfilesKey);
      }
    }
    return UseSmileIDSampleSecureProfilesRepository._(
      secure,
      UseSmileIDSampleProfilesCodec.decode(stored),
    );
  }

  @override
  UseSmileIDSampleProfiles read() => UseSmileIDSampleProfilesCodec.decode(
    UseSmileIDSampleProfilesCodec.encode(_current),
  );

  @override
  Future<void> write(UseSmileIDSampleProfiles profiles) {
    final String encoded = UseSmileIDSampleProfilesCodec.encode(profiles);
    _current = UseSmileIDSampleProfilesCodec.decode(encoded);
    return _writes = _writes.then((_) async {
      try {
        await _storage.write(key: useSmileIDSampleProfilesKey, value: encoded);
      } on Object {
        // The platform store can refuse a write; the next change tries again with the whole record.
      }
    });
  }

  /// The same Keychain account as the token session.
  static const IOSOptions _keychain = IOSOptions(
    accountName: 'usesmileid_sample',
    accessibility: KeychainAccessibility.unlocked_this_device,
  );
}
