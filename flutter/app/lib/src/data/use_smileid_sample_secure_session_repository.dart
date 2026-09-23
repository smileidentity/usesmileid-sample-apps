import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sample_ui/sample_ui.dart';

/// The token session in the Keychain or Keystore.
class UseSmileIDSampleSecureSessionRepository
    extends UseSmileIDSampleRecordSessionRepository {
  /// [storage] is injectable so a test can stand in for the platform.
  UseSmileIDSampleSecureSessionRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(iOptions: _keychain);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRecord() => _storage.read(key: _key);

  @override
  Future<void> writeRecord(String? record) => record == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: record);

  /// Matches the native iOS app's Keychain item.
  static const IOSOptions _keychain = IOSOptions(
    accountName: 'usesmileid_sample',
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  static const String _key = 'token_session';
}
