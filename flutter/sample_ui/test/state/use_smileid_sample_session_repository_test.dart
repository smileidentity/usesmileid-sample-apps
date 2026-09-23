import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The one record: a live token or its ended marker, never both, under the keys every platform reads.
void main() {
  test('a fresh store holds neither half', () async {
    final UseSmileIDSampleSessionRecord record =
        await UseSmileIDSampleMemorySessionRepository().read();
    expect(record.live, isNull);
    expect(record.ended, isNull);
  });

  test(
    'linking stores the token under the Android key and reads it back decoded',
    () async {
      final _Store store = _Store();
      await store.link(_session);
      expect(jsonDecode(store.bytes!), <String, Object?>{
        'token_session_token': _token,
      });
      expect((await store.read()).live?.id, _session.id);
    },
  );

  test(
    'retiring deletes the credential and keeps only the handle and deadline',
    () async {
      final _Store store = _Store();
      await store.link(_session);
      await store.retire(_session);
      expect(store.bytes, isNot(contains(_token)));
      final UseSmileIDSampleSessionRecord record = await store.read();
      expect(record.live, isNull);
      expect(
        record.ended,
        UseSmileIDSampleEndedSession(
          id: _session.id,
          endedAtMillis: _session.expiresAtMillis,
        ),
      );
    },
  );

  test(
    'a new link clears the ended marker, and sign out clears both',
    () async {
      final _Store store = _Store();
      await store.retire(_session);
      await store.link(_session);
      expect((await store.read()).ended, isNull);
      await store.clear();
      expect(store.bytes, isNull);
    },
  );

  test('a stored record that no longer reads is no record', () {
    expect(UseSmileIDSampleSessionRecord.decode('not json').live, isNull);
    expect(UseSmileIDSampleSessionRecord.decode('[1]').ended, isNull);
    expect(
      UseSmileIDSampleSessionRecord.decode(
        jsonEncode(<String, Object?>{'token_session_token': 'nope'}),
      ).live,
      isNull,
    );
  });
}

class _Store extends UseSmileIDSampleRecordSessionRepository {
  String? bytes;

  @override
  Future<String?> readRecord() async => bytes;

  @override
  Future<void> writeRecord(String? record) async => bytes = record;
}

final String _token = <String>[
  '{"alg":"none","typ":"JWT"}',
  '{"iat":1755500000,"exp":1755500900,"api_url":"https://testapi.smileidentity.com/v3"}',
  'sample-signature',
].map((String it) => base64Url.encode(utf8.encode(it)).replaceAll('=', '')).join('.');

final UseSmileIDSampleTokenSession _session =
    UseSmileIDSampleTokenDecoder.session(_token)!;
