import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_environment.dart';
import '../model/use_smileid_sample_product.dart';
import 'use_smileid_sample_digest.dart';
import 'use_smileid_sample_token_session.dart';

/// What a v3 token binds; every PII value is a vault reference, so only presence is read for those.
@immutable
class UseSmileIDSampleTokenBindings {
  /// Everything unbound, which is what a token with no `payload` claim carries.
  const UseSmileIDSampleTokenBindings({
    this.givenNames = false,
    this.lastName = false,
    this.email = false,
    this.phoneNumber = false,
    this.consent,
    this.country,
    this.idType,
    this.idNumberReference,
    this.callbackUrl,
  });

  /// Whether the given name is bound.
  final bool givenNames;

  /// Whether the family name is bound.
  final bool lastName;

  /// Whether the email is bound.
  final bool email;

  /// Whether the phone number is bound.
  final bool phoneNumber;

  /// The consent record, null when none is bound.
  final UseSmileIDSampleTokenConsent? consent;

  /// The plaintext country code.
  final String? country;

  /// The plaintext ID type.
  final String? idType;

  /// The vault reference standing in for the ID number, the only form a token carries it in.
  final String? idNumberReference;

  /// A webhook URL or a `callback_` id; the server injects it over whatever the body carried.
  final String? callbackUrl;

  /// Whether the token carries every ID parameter [product] submits, stricter than Document Verification's validator.
  bool bindsIdDetails(UseSmileIDSampleProduct product) => switch (product) {
    UseSmileIDSampleProduct.enhancedKyc ||
    UseSmileIDSampleProduct.biometricKyc =>
      _present(country) && _present(idType) && _present(idNumberReference),
    UseSmileIDSampleProduct.documentVerification ||
    UseSmileIDSampleProduct.enhancedDocumentVerification =>
      _present(country) && _present(idType),
    UseSmileIDSampleProduct.smartSelfieEnrollment ||
    UseSmileIDSampleProduct.smartSelfieAuth => true,
  };

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleTokenBindings &&
      other.givenNames == givenNames &&
      other.lastName == lastName &&
      other.email == email &&
      other.phoneNumber == phoneNumber &&
      other.consent == consent &&
      other.country == country &&
      other.idType == idType &&
      other.idNumberReference == idNumberReference &&
      other.callbackUrl == callbackUrl;

  @override
  int get hashCode => Object.hash(
    givenNames,
    lastName,
    email,
    phoneNumber,
    consent,
    country,
    idType,
    idNumberReference,
    callbackUrl,
  );

  /// Presence only: every one of these is a claim value, and one is a vault reference.
  @override
  String toString() =>
      'UseSmileIDSampleTokenBindings(givenNames: $givenNames, lastName: $lastName, '
      'email: $email, phoneNumber: $phoneNumber, consent: ${consent != null}, '
      'country: ${country != null}, idType: ${idType != null}, '
      'idNumberReference: ${idNumberReference != null}, callbackUrl: ${callbackUrl != null})';
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;

/// The consent record bound into the token; `granted` is true or absent, as the SDK reads `false` as no binding.
@immutable
class UseSmileIDSampleTokenConsent {
  /// All four subfields optional, so an incomplete binding can be represented and reported.
  const UseSmileIDSampleTokenConsent({
    this.granted,
    this.grantedAt,
    this.noticeLanguage,
    this.noticePrivacyPolicyUrl,
  });

  /// True, or null.
  final bool? granted;

  /// When consent was given.
  final String? grantedAt;

  /// The notice's language.
  final String? noticeLanguage;

  /// The notice's privacy policy.
  final String? noticePrivacyPolicyUrl;

  /// True when the token alone satisfies consent, which is when the SDK drops its consent screen.
  bool get isComplete =>
      granted == true &&
      _present(grantedAt) &&
      _present(noticeLanguage) &&
      _present(noticePrivacyPolicyUrl);

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleTokenConsent &&
      other.granted == granted &&
      other.grantedAt == grantedAt &&
      other.noticeLanguage == noticeLanguage &&
      other.noticePrivacyPolicyUrl == noticePrivacyPolicyUrl;

  @override
  int get hashCode =>
      Object.hash(granted, grantedAt, noticeLanguage, noticePrivacyPolicyUrl);
}

/// Either the session a token describes, or why it is not one.
sealed class UseSmileIDSampleTokenDecode {
  const UseSmileIDSampleTokenDecode();
}

/// Decoded only, never verified: the sample holds no signing key.
class UseSmileIDSampleTokenDecoded extends UseSmileIDSampleTokenDecode {
  /// [session] is what the claims describe.
  const UseSmileIDSampleTokenDecoded(this.session);

  /// The session the claims describe.
  final UseSmileIDSampleTokenSession session;
}

/// Names the claim or structure that failed; never a value, bar the `api_url` host, which is public.
class UseSmileIDSampleTokenRejected extends UseSmileIDSampleTokenDecode {
  /// [reason] is shown to the person who entered the token.
  const UseSmileIDSampleTokenRejected(this.reason);

  /// Why the token is not a session.
  final String reason;
}

/// Reads the claims a session is made of: a documented duplicate of the SDK's binding rules, whose payload accessor is internal.
abstract final class UseSmileIDSampleTokenDecoder {
  /// Decoded when the segments, the iat/exp pair and the api_url all read; otherwise the first failure.
  static UseSmileIDSampleTokenDecode decode(String token) {
    final String trimmed = token.trim();
    final List<String> segments = trimmed.split('.');
    if (segments.length != _segments ||
        segments.any((String it) => !_base64Url.hasMatch(it))) {
      return _reject(
        'A token is three dot-separated base64url segments; this is not.',
      );
    }
    final String? claims = _decodeSegment(segments[1]);
    if (claims == null) {
      return _reject("The token's payload segment is not base64url.");
    }
    final Object? parsed = _parse(claims);
    if (parsed is! Map<String, Object?>) {
      return _reject("The token's payload segment is not a JSON object.");
    }
    final int? issuedAt = _seconds(parsed['iat']);
    if (issuedAt == null) {
      return _reject('The token carries no numeric iat claim.');
    }
    final int? expires = _seconds(parsed['exp']);
    if (expires == null) {
      return _reject('The token carries no numeric exp claim.');
    }
    if (expires <= issuedAt) {
      return _reject("The token's exp claim is not after its iat claim.");
    }
    // Refused rather than defaulted: a silent sandbox fallback sends a production token to the wrong host.
    final String? apiUrl = _string(parsed['api_url']);
    if (apiUrl == null || apiUrl.trim().isEmpty) {
      return _reject(
        'The token carries no api_url claim, so nothing says which environment it was minted for.',
      );
    }
    final UseSmileIDSampleEnvironment? environment = environmentFor(apiUrl);
    if (environment == null) {
      final String? host = apiUrlHost(apiUrl);
      return _reject(
        host == null
            ? "The token's api_url is not a URL, so it names no environment."
            : "The token's api_url names $host, which is not a Smile ID environment.",
      );
    }
    final String? partnerId = _string(parsed['partner_id']);
    final Object? payload = parsed['payload'];
    return UseSmileIDSampleTokenDecoded(
      UseSmileIDSampleTokenSession(
        id: _handle(trimmed, _string(parsed['jti'])),
        token: trimmed,
        issuedAtMillis: issuedAt * _millisPerSecond,
        expiresAtMillis: expires * _millisPerSecond,
        bindings: payload is Map<String, Object?>
            ? _bindings(payload)
            : const UseSmileIDSampleTokenBindings(),
        partnerId: partnerId == null || partnerId.trim().isEmpty
            ? null
            : partnerId,
        environment: environment,
      ),
    );
  }

  /// The session a token describes, or null: a stored token that no longer decodes is no session.
  static UseSmileIDSampleTokenSession? session(String token) => switch (decode(
    token,
  )) {
    UseSmileIDSampleTokenDecoded(:final UseSmileIDSampleTokenSession session) =>
      session,
    UseSmileIDSampleTokenRejected() => null,
  };

  /// A display handle, never a prefix of the credential: the token's own `jti`, else a digest of it.
  static String _handle(String token, String? jti) =>
      jti != null && jti.trim().isNotEmpty
      ? jti
      : useSmileIDSampleDigest(token);

  static UseSmileIDSampleTokenBindings _bindings(
    Map<String, Object?> json,
  ) => UseSmileIDSampleTokenBindings(
    givenNames: _binds(json['given_names']),
    lastName: _binds(json['last_name']),
    email: _binds(json['email']),
    phoneNumber: _binds(json['phone_number']),
    consent: _consent(json['consent']),
    // Non-blank, unlike the presence flags: these are read as values, and a blank one would win.
    country: _value(json['country']),
    idType: _value(json['id_type']),
    idNumberReference: _value(json['id_number']),
    callbackUrl: _value(json['callback_url']),
  );

  /// An empty consent object is no consent, and a non-boolean `granted` never counts toward one.
  static UseSmileIDSampleTokenConsent? _consent(Object? claim) {
    if (claim is! Map<String, Object?> || claim.isEmpty) {
      return null;
    }
    return UseSmileIDSampleTokenConsent(
      granted: claim['granted'] == true ? true : null,
      grantedAt: _string(claim['granted_at']),
      noticeLanguage: _string(claim['notice_language']),
      noticePrivacyPolicyUrl: _string(claim['notice_privacy_policy_url']),
    );
  }

  /// A field is token-bound iff the claim carries it as a non-empty string.
  static bool _binds(Object? claim) => claim is String && claim.isNotEmpty;

  static String? _string(Object? claim) => claim is String ? claim : null;

  static String? _value(Object? claim) =>
      claim is String && claim.trim().isNotEmpty ? claim : null;

  /// RFC 7519 allows a non-integer NumericDate, so it truncates; a string is never a time.
  static int? _seconds(Object? claim) =>
      claim is num && claim.isFinite ? claim.truncate() : null;

  /// Padding-optional: JWT segments are minted without it, and a pasted one may carry it.
  static String? _decodeSegment(String segment) {
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(segment)));
    } on FormatException {
      return null;
    }
  }

  /// Null on anything malformed or nested past the cap, as untrusted input from a clipboard or a QR.
  static Object? _parse(String text) {
    try {
      final Object? value = jsonDecode(text);
      return _depthOf(value, 0) ? value : null;
    } on FormatException {
      return null;
    }
  }

  static bool _depthOf(Object? value, int depth) {
    if (depth > _maxDepth) {
      return false;
    }
    return switch (value) {
      final Map<String, Object?> map => map.values.every(
        (Object? it) => _depthOf(it, depth + 1),
      ),
      final List<Object?> list => list.every(
        (Object? it) => _depthOf(it, depth + 1),
      ),
      _ => true,
    };
  }

  static UseSmileIDSampleTokenRejected _reject(String reason) =>
      UseSmileIDSampleTokenRejected(reason);

  static const int _segments = 3;
  static const int _millisPerSecond = 1000;
  static const int _maxDepth = 32;
  static final RegExp _base64Url = RegExp(r'^[A-Za-z0-9_-]+$');
}
