import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:sample_ui/src/state/use_smileid_sample_digest.dart';

/// The decode rules, held against the SDK's own: the same cases Android and iOS pin theirs to.
void main() {
  test('a token is three base64url segments or it is not a token', () {
    for (final String candidate in <String>[
      'not-a-jwt',
      'two.segments',
      'four.of.these.segments',
      'header..signature',
      'header.pay load.signature',
      'header.payload+slash.signature',
    ]) {
      expect(
        _decode(candidate),
        isA<UseSmileIDSampleTokenRejected>(),
        reason: candidate,
      );
    }
  });

  test('surrounding whitespace is trimmed rather than rejected', () {
    expect(_session('  ${_token()}\n'), isNotNull);
  });

  test('a payload segment that is not base64url json is rejected', () {
    expect(_decode('aGVhZGVy.@@@@.c2ln'), isA<UseSmileIDSampleTokenRejected>());
    expect(_decode(_jwt('[1,2,3]')), isA<UseSmileIDSampleTokenRejected>());
    expect(_decode(_jwt('{"exp":')), isA<UseSmileIDSampleTokenRejected>());
  });

  test('both time claims are required, and exp must be after iat', () {
    expect(
      _decode(_jwt('{"iat":$_iat}')),
      isA<UseSmileIDSampleTokenRejected>(),
    );
    expect(
      _decode(_jwt('{"exp":$_exp}')),
      isA<UseSmileIDSampleTokenRejected>(),
    );
    expect(
      _decode(_jwt('{"iat":$_exp,"exp":$_iat}')),
      isA<UseSmileIDSampleTokenRejected>(),
    );
    expect(
      _decode(_jwt('{"iat":$_iat,"exp":"$_exp"}')),
      isA<UseSmileIDSampleTokenRejected>(),
    );
  });

  test('a rejection names the structure that failed and never the token', () {
    final String candidate = _jwt('{"iat":$_iat}');
    final String reason = _rejection(candidate);
    expect(reason, contains('exp'));
    expect(reason, isNot(contains(candidate.split('.')[1])));
  });

  test('epoch seconds become the absolute deadline in millis', () {
    final UseSmileIDSampleTokenSession session = _session(_token())!;
    expect(session.issuedAtMillis, _iat * 1000);
    expect(session.expiresAtMillis, _exp * 1000);
  });

  test('the handle is the jti when the token carries one', () {
    expect(
      _session(
        _jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl,"jti":"sess_7f2"}'),
      )!.id,
      'sess_7f2',
    );
  });

  test(
    'without a jti the handle is a short digest, never a prefix of the credential',
    () {
      final String token = _token();
      final UseSmileIDSampleTokenSession session = _session(token)!;
      expect(session.id, matches(RegExp(r'^[0-9a-f]{8}$')));
      expect(token.startsWith(session.id), isFalse);
      expect(token.contains(session.id), isFalse);
      expect(_session(token)!.id, session.id);
    },
  );

  test('the digest is SHA-256, checked against the standard vector', () {
    expect(
      useSmileIDSampleDigest('abc', bytes: 32),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(useSmileIDSampleDigest('', bytes: 4), 'e3b0c442');
  });

  test(
    'toString redacts the token, because that is how a credential reaches a log',
    () {
      final UseSmileIDSampleTokenSession session = _session(_token())!;
      expect(session.toString(), isNot(contains(session.token)));
    },
  );

  test(
    'each known host maps to its environment, whatever the scheme, port, path or case',
    () {
      const Map<String, UseSmileIDSampleEnvironment> hosts =
          <String, UseSmileIDSampleEnvironment>{
            'https://testapi.smileidentity.com/v3':
                UseSmileIDSampleEnvironment.sandbox,
            'https://testapi.smileidentity.com/':
                UseSmileIDSampleEnvironment.sandbox,
            'https://testapi.smileidentity.com':
                UseSmileIDSampleEnvironment.sandbox,
            'HTTPS://TestApi.SmileIdentity.COM/v3':
                UseSmileIDSampleEnvironment.sandbox,
            'https://api.smileidentity.com/':
                UseSmileIDSampleEnvironment.production,
            'https://api.smileidentity.com/v3':
                UseSmileIDSampleEnvironment.production,
            'http://api.smileidentity.com/v3':
                UseSmileIDSampleEnvironment.production,
            'https://api.smileidentity.com:443/v3':
                UseSmileIDSampleEnvironment.production,
          };
      hosts.forEach((String url, UseSmileIDSampleEnvironment expected) {
        expect(
          _session(_tokenWithApiUrl('"api_url":"$url"'))?.environment,
          expected,
          reason: url,
        );
      });
    },
  );

  test(
    'an unrecognised host is refused rather than falling back, and the rejection names it',
    () {
      expect(
        _rejection(
          _tokenWithApiUrl(
            '"api_url":"https://api.smileidentity.com.evil.test/v3"',
          ),
        ),
        contains('api.smileidentity.com.evil.test'),
      );
    },
  );

  test('a host that only looks like one of ours is not one of ours', () {
    for (final String url in <String>[
      'https://smileidentity.com/v3',
      'https://api.smileidentity.com.br/v3',
      'https://testapi.smileidentity.co/v3',
      'testapi.smileidentity.com/v3',
    ]) {
      expect(
        _decode(_tokenWithApiUrl('"api_url":"$url"')),
        isA<UseSmileIDSampleTokenRejected>(),
        reason: url,
      );
    }
  });

  test(
    'a malformed api_url is refused, and says so without pretending to name a host',
    () {
      expect(
        _rejection(_tokenWithApiUrl('"api_url":"not a url at all"')),
        contains('not a URL'),
      );
    },
  );

  test('an absent, blank or non-string api_url refuses the token', () {
    for (final String claim in <String>[
      '"jti":"sess_7f2"',
      '"api_url":""',
      '"api_url":"  "',
      '"api_url":42',
    ]) {
      expect(
        _rejection(_tokenWithApiUrl(claim)),
        contains('api_url'),
        reason: claim,
      );
    }
  });

  test(
    'the redacted toString reports the environment as a value, because a host is public',
    () {
      expect(_session(_token()).toString(), contains('Sandbox'));
    },
  );

  test('a field binds only when the claim carries it as a non-empty string', () {
    final UseSmileIDSampleTokenBindings bindings = _bindings(
      '"given_names":"vault_given_names","last_name":"","email":42,"phone_number":null',
    );
    expect(bindings.givenNames, isTrue);
    expect(
      bindings.lastName,
      isFalse,
      reason: 'an empty string is not a binding',
    );
    expect(bindings.email, isFalse, reason: 'a number is not a binding');
    expect(bindings.phoneNumber, isFalse, reason: 'null is not a binding');
  });

  test('an object or array in a user-detail field is not a binding', () {
    final UseSmileIDSampleTokenBindings bindings = _bindings(
      '"given_names":{"vault":"x"},"last_name":["x"]',
    );
    expect(bindings.givenNames, isFalse);
    expect(bindings.lastName, isFalse);
  });

  test(
    "the two plaintext claims and the ID number's vault reference are all read",
    () {
      final UseSmileIDSampleTokenBindings bindings = _bindings(
        '"country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01"',
      );
      expect(bindings.country, 'KE');
      expect(bindings.idType, 'NATIONAL_ID');
      expect(bindings.idNumberReference, 'pii_fixture01');
    },
  );

  test('a blank value claim reads as absent, unlike the presence flags', () {
    final UseSmileIDSampleTokenBindings bindings = _bindings(
      '"country":" ","id_type":"","id_number":"  "',
    );
    expect(bindings.country, isNull);
    expect(bindings.idType, isNull);
    expect(bindings.idNumberReference, isNull);
  });

  test(
    'the KYC products need country, ID type and the ID number reference before their form is skipped',
    () {
      const UseSmileIDSampleTokenBindings bound = UseSmileIDSampleTokenBindings(
        country: 'KE',
        idType: 'NATIONAL_ID',
        idNumberReference: 'pii_1',
      );
      for (final UseSmileIDSampleProduct product in <UseSmileIDSampleProduct>[
        UseSmileIDSampleProduct.enhancedKyc,
        UseSmileIDSampleProduct.biometricKyc,
      ]) {
        expect(bound.bindsIdDetails(product), isTrue);
        expect(
          const UseSmileIDSampleTokenBindings(
            country: 'KE',
            idType: 'NATIONAL_ID',
          ).bindsIdDetails(product),
          isFalse,
        );
        expect(
          const UseSmileIDSampleTokenBindings(
            country: 'KE',
            idNumberReference: 'pii_1',
          ).bindsIdDetails(product),
          isFalse,
        );
        expect(
          const UseSmileIDSampleTokenBindings(
            idType: 'NATIONAL_ID',
            idNumberReference: 'pii_1',
          ).bindsIdDetails(product),
          isFalse,
        );
      }
    },
  );

  test(
    'both document products need country and ID type, and neither needs an ID number',
    () {
      const UseSmileIDSampleTokenBindings bound = UseSmileIDSampleTokenBindings(
        country: 'KE',
        idType: 'NATIONAL_ID',
      );
      for (final UseSmileIDSampleProduct product in <UseSmileIDSampleProduct>[
        UseSmileIDSampleProduct.documentVerification,
        UseSmileIDSampleProduct.enhancedDocumentVerification,
      ]) {
        expect(bound.bindsIdDetails(product), isTrue);
        // The validator accepts a null idType, but the form is where the document type is chosen.
        expect(
          const UseSmileIDSampleTokenBindings(
            country: 'KE',
          ).bindsIdDetails(product),
          isFalse,
        );
        expect(
          const UseSmileIDSampleTokenBindings(
            idType: 'NATIONAL_ID',
          ).bindsIdDetails(product),
          isFalse,
        );
      }
    },
  );

  test('a product that submits no ID parameters is never sent to the form', () {
    for (final UseSmileIDSampleProduct product in <UseSmileIDSampleProduct>[
      UseSmileIDSampleProduct.smartSelfieEnrollment,
      UseSmileIDSampleProduct.smartSelfieAuth,
    ]) {
      expect(
        const UseSmileIDSampleTokenBindings().bindsIdDetails(product),
        isTrue,
      );
    }
  });

  test(
    'the bindings toString reports presence, because a vault reference is still a claim value',
    () {
      final String text = _bindings(
        '"country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01"',
      ).toString();
      for (final String value in <String>[
        'KE',
        'NATIONAL_ID',
        'pii_fixture01',
      ]) {
        expect(text, isNot(contains(value)));
      }
    },
  );

  test('an absent or empty consent object is no consent binding', () {
    expect(_bindings('"email":"vault_email"').consent, isNull);
    expect(_bindings('"consent":{}').consent, isNull);
    expect(_bindings('"consent":[]').consent, isNull);
    expect(_bindings('"consent":"granted"').consent, isNull);
  });

  test(
    'granted false or non-boolean never counts toward a consent binding',
    () {
      for (final String granted in <String>['false', '"true"', '1', 'null']) {
        final UseSmileIDSampleTokenConsent consent = _bindings(
          '"consent":{"granted":$granted,"granted_at":"$_grantedAt"}',
        ).consent!;
        expect(consent.granted, isNull, reason: 'granted:$granted');
        expect(consent.isComplete, isFalse);
      }
    },
  );

  test(
    'consent is complete only with granted true and all three subfields non-blank',
    () {
      expect(_bindings(_consent()).consent!.isComplete, isTrue);
      expect(_bindings(_consent(grantedAt: '')).consent!.isComplete, isFalse);
      expect(_bindings(_consent(language: ' ')).consent!.isComplete, isFalse);
      expect(_bindings(_consent(policyUrl: null)).consent!.isComplete, isFalse);
      expect(
        _bindings(_consent(granted: 'false')).consent!.isComplete,
        isFalse,
      );
    },
  );

  test('a non-string consent subfield reads as absent', () {
    final UseSmileIDSampleTokenConsent consent = _bindings(
      '"consent":{"granted":true,"granted_at":1755500000}',
    ).consent!;
    expect(consent.grantedAt, isNull);
    expect(consent.isComplete, isFalse);
  });

  test('required user details are both names plus one contact field', () {
    expect(
      const UseSmileIDSampleTokenBindings(
        givenNames: true,
        lastName: true,
      ).bindsRequiredUserDetails,
      isFalse,
      reason: 'names alone relax nothing',
    );
    expect(
      const UseSmileIDSampleTokenBindings(
        givenNames: true,
        lastName: true,
        email: true,
      ).bindsRequiredUserDetails,
      isTrue,
    );
    expect(
      const UseSmileIDSampleTokenBindings(
        givenNames: true,
        lastName: true,
        phoneNumber: true,
      ).bindsRequiredUserDetails,
      isTrue,
    );
    expect(
      const UseSmileIDSampleTokenBindings(
        lastName: true,
        email: true,
      ).bindsRequiredUserDetails,
      isFalse,
    );
    expect(
      const UseSmileIDSampleTokenBindings(
        email: true,
        phoneNumber: true,
      ).bindsRequiredUserDetails,
      isFalse,
    );
  });

  test(
    'a payload claim of the wrong shape leaves the token usable and unbound',
    () {
      expect(
        _session(
          _jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl,"payload":"nonsense"}'),
        )!.bindings,
        const UseSmileIDSampleTokenBindings(),
      );
    },
  );

  test(
    "nesting past the reader's depth cap is rejected rather than crashing",
    () {
      final String deep = '${'[' * 200}${']' * 200}';
      expect(
        _decode(_jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl,"payload":$deep}')),
        isA<UseSmileIDSampleTokenRejected>(),
      );
    },
  );

  test('the partner id is read, and a blank one is none', () {
    expect(
      _session(
        _jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl,"partner_id":"p_fixture"}'),
      )!.partnerId,
      'p_fixture',
    );
    expect(
      _session(
        _jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl,"partner_id":" "}'),
      )!.partnerId,
      isNull,
    );
  });
}

UseSmileIDSampleTokenDecode _decode(String token) =>
    UseSmileIDSampleTokenDecoder.decode(token);

UseSmileIDSampleTokenSession? _session(String token) =>
    UseSmileIDSampleTokenDecoder.session(token);

String _rejection(String token) =>
    (_decode(token) as UseSmileIDSampleTokenRejected).reason;

UseSmileIDSampleTokenBindings _bindings(String payloadFields) => _session(
  _jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl,"payload":{$payloadFields}}'),
)!.bindings;

String _consent({
  String granted = 'true',
  String? grantedAt = _grantedAt,
  String? language = 'en',
  String? policyUrl = 'https://smile.id/privacy-policy',
}) =>
    '"consent":{"granted":$granted,"granted_at":${_quoted(grantedAt)},'
    '"notice_language":${_quoted(language)},"notice_privacy_policy_url":${_quoted(policyUrl)}}';

String _quoted(String? value) => value == null ? 'null' : '"$value"';

String _token() => _jwt('{"iat":$_iat,"exp":$_exp,$_sandboxUrl}');

String _tokenWithApiUrl(String claim) =>
    _jwt('{"iat":$_iat,"exp":$_exp,$claim}');

String _jwt(String claims) => <String>[_header, claims, 'sample-signature']
    .map((String it) => base64Url.encode(utf8.encode(it)).replaceAll('=', ''))
    .join('.');

const int _iat = 1755500000;
const int _exp = 1755500900;
const String _grantedAt = '2026-08-18T09:00:00Z';
const String _header = '{"alg":"none","typ":"JWT"}';
const String _sandboxUrl = '"api_url":"https://testapi.smileidentity.com/v3"';
