import 'dart:convert';

import 'package:sample_ui/sample_ui.dart';

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

  /// What a simulated scan links: the same unsigned shape over the chosen span and bindings, with nonsense PII.
  static String session({
    required UseSmileIDSampleSimulatedSpan span,
    required UseSmileIDSampleSimulatedBindings bindings,
    required UseSmileIDSampleEnvironment environment,
    required int nowMillis,
  }) {
    final int nowSeconds = nowMillis ~/ _millisPerSecond;
    // An ended span is minted wholly in the past, which is the only way to reach the expiry gate.
    final int issuedAt = span.inPast
        ? nowSeconds - span.span.inSeconds - _endedLagSeconds
        : nowSeconds;
    final List<String> claims = <String>[
      '"iat":$issuedAt',
      '"exp":${issuedAt + span.span.inSeconds}',
      // With the path a real claim carries, so the fixture exercises the host match.
      '"api_url":"${environment.baseUrl}$_apiPath"',
      if (bindings.binds) _payloadClaim(bindings, issuedAt),
    ];
    return <String>[
      _header,
      '{${claims.join(',')}}',
      _signature,
    ].map(_base64Url).join('.');
  }

  static String _payloadClaim(
    UseSmileIDSampleSimulatedBindings bindings,
    int issuedAtSeconds,
  ) {
    final List<String> fields = <String>[
      if (bindings.userDetails) ...<String>[
        for (final String field in _vaultedFields) '"$field":"vault_$field"',
        // The two the Portal leaves in plaintext, so a decode can read them back.
        '"country":"${UseSmileIDSampleCountry.ke.code}"',
        '"id_type":"${UseSmileIDSampleIdType.nationalId.id}"',
      ],
      if (bindings.consent) _consentClaim(issuedAtSeconds),
    ];
    return '"payload":{${fields.join(',')}}';
  }

  /// All four subfields: the SDK treats a partial binding as a build error, not a partial relaxation.
  static String _consentClaim(int issuedAtSeconds) {
    final String grantedAt =
        '${DateTime.fromMillisecondsSinceEpoch(issuedAtSeconds * _millisPerSecond, isUtc: true).toIso8601String().split('.').first}Z';
    return '"consent":{"granted":true,"granted_at":"$grantedAt",'
        '"notice_language":"en","notice_privacy_policy_url":"$_privacyPolicyUrl"}';
  }

  static String _base64Url(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  static const String _header = '{"alg":"none","typ":"JWT"}';
  static const String _signature = 'sample-signature';
  static const int _millisPerSecond = 1000;
  static const int _validitySeconds = 3600;
  static const int _endedLagSeconds = 60;
  static const String _apiPath = 'v3';
  static const String _privacyPolicyUrl = 'https://smile.id/privacy-policy';
  static const List<String> _vaultedFields = <String>[
    'given_names',
    'last_name',
    'email',
    'phone_number',
    'id_number',
  ];
}
