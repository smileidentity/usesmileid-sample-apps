import 'dart:convert';

/// Structurally valid unsigned JWTs — fixtures the scenarios demand, never credentials.
abstract final class UseSmileIDSampleFlowTokens {
  /// A token whose `exp` is an hour away, or an hour past when [expired].
  static String token({required bool expired, required int nowMillis}) {
    final int exp =
        nowMillis ~/ _millisPerSecond +
        (expired ? -_validitySeconds : _validitySeconds);
    return <String>[
      _header,
      '{"exp":$exp}',
      _signature,
    ].map(_base64Url).join('.');
  }

  /// What `badRefresh` hands back, so the failure path has something unusable to reject.
  static String malformed() => 'sample-not-a-jwt';

  static String _base64Url(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  static const String _header = '{"alg":"none","typ":"JWT"}';
  static const String _signature = 'sample-signature';
  static const int _millisPerSecond = 1000;
  static const int _validitySeconds = 3600;
}
