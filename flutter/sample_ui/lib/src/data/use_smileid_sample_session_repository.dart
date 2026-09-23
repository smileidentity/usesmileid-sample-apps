import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../state/use_smileid_sample_token_decoder.dart';
import '../state/use_smileid_sample_token_session.dart';

/// A session that has run out, remembered without its credential.
@immutable
class UseSmileIDSampleEndedSession {
  /// [id] is the handle, never a prefix of the token.
  const UseSmileIDSampleEndedSession({
    required this.id,
    required this.endedAtMillis,
  });

  /// The ended session's handle.
  final String id;

  /// Its deadline, in epoch milliseconds.
  final int endedAtMillis;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleEndedSession &&
      other.id == id &&
      other.endedAtMillis == endedAtMillis;

  @override
  int get hashCode => Object.hash(id, endedAtMillis);
}

/// At most one half is ever set.
@immutable
class UseSmileIDSampleSessionRecord {
  /// Neither half, which is a fresh install.
  const UseSmileIDSampleSessionRecord({this.live, this.ended});

  /// The linked session.
  final UseSmileIDSampleTokenSession? live;

  /// The session that ran out, once its token has been deleted.
  final UseSmileIDSampleEndedSession? ended;

  /// Encodes under the Android store's keys.
  String encode() => jsonEncode(<String, Object?>{
    if (live != null) _token: live!.token,
    if (ended != null) _endedId: ended!.id,
    if (ended != null) _endedAt: ended!.endedAtMillis,
  });

  /// Decodes a stored record; an unreadable one is no record.
  static UseSmileIDSampleSessionRecord decode(String? stored) {
    if (stored == null) {
      return const UseSmileIDSampleSessionRecord();
    }
    final Object? json;
    try {
      json = jsonDecode(stored);
    } on FormatException {
      return const UseSmileIDSampleSessionRecord();
    }
    if (json is! Map<String, Object?>) {
      return const UseSmileIDSampleSessionRecord();
    }
    final Object? token = json[_token];
    final Object? endedId = json[_endedId];
    final Object? endedAt = json[_endedAt];
    return UseSmileIDSampleSessionRecord(
      live: token is String
          ? UseSmileIDSampleTokenDecoder.session(token)
          : null,
      ended: endedId is String
          ? UseSmileIDSampleEndedSession(
              id: endedId,
              endedAtMillis: endedAt is int ? endedAt : 0,
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleSessionRecord &&
      other.live == live &&
      other.ended == ended;

  @override
  int get hashCode => Object.hash(live, ended);

  static const String _token = 'token_session_token';
  static const String _endedId = 'ended_session_id';
  static const String _endedAt = 'ended_session_at';
}

/// Where the token session is kept, apart from the switches.
abstract interface class UseSmileIDSampleSessionRepository {
  /// Both halves from one read.
  Future<UseSmileIDSampleSessionRecord> read();

  /// Links a decoded session, clearing any ended marker.
  Future<UseSmileIDSampleSessionRecord> link(
    UseSmileIDSampleTokenSession session,
  );

  /// Replaces the token with its ended marker.
  Future<UseSmileIDSampleSessionRecord> retire(
    UseSmileIDSampleTokenSession session,
  );

  /// Sign out: clears the session with no ended marker.
  Future<UseSmileIDSampleSessionRecord> clear();
}

/// Stores the record whole: a secure store in an app, memory in a test.
abstract class UseSmileIDSampleRecordSessionRepository
    implements UseSmileIDSampleSessionRepository {
  /// Reads the stored record, null when there is none.
  @protected
  Future<String?> readRecord();

  /// Replaces the record; null deletes it.
  @protected
  Future<void> writeRecord(String? record);

  @override
  Future<UseSmileIDSampleSessionRecord> read() async =>
      UseSmileIDSampleSessionRecord.decode(await readRecord());

  @override
  Future<UseSmileIDSampleSessionRecord> link(
    UseSmileIDSampleTokenSession session,
  ) => _write(UseSmileIDSampleSessionRecord(live: session));

  @override
  Future<UseSmileIDSampleSessionRecord> retire(
    UseSmileIDSampleTokenSession session,
  ) => _write(
    UseSmileIDSampleSessionRecord(
      ended: UseSmileIDSampleEndedSession(
        id: session.id,
        endedAtMillis: session.expiresAtMillis,
      ),
    ),
  );

  @override
  Future<UseSmileIDSampleSessionRecord> clear() async {
    await writeRecord(null);
    return const UseSmileIDSampleSessionRecord();
  }

  Future<UseSmileIDSampleSessionRecord> _write(
    UseSmileIDSampleSessionRecord record,
  ) async {
    await writeRecord(record.encode());
    return record;
  }
}

/// The record in memory, which is what a test and a preview want.
class UseSmileIDSampleMemorySessionRepository
    extends UseSmileIDSampleRecordSessionRepository {
  /// [initial] is the record a test starts from.
  UseSmileIDSampleMemorySessionRepository([
    UseSmileIDSampleSessionRecord initial =
        const UseSmileIDSampleSessionRecord(),
  ]) : _record = initial.live == null && initial.ended == null
           ? null
           : initial.encode();

  String? _record;

  @override
  Future<String?> readRecord() async => _record;

  @override
  Future<void> writeRecord(String? record) async => _record = record;
}
