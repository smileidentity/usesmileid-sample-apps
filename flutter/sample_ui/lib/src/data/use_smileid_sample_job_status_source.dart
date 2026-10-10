import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_status.dart';
import '../use_smileid_sample_strings.dart';

/// What a refresh did, so the screen can say so. The labels are product strings, identical across the four apps.
sealed class UseSmileIDSampleStatusRefresh {
  /// Const so every outcome without fields can be a shared instance.
  const UseSmileIDSampleStatusRefresh();
}

/// The server answered with a verdict, which is the only outcome that writes.
@immutable
class UseSmileIDSampleStatusUpdated extends UseSmileIDSampleStatusRefresh {
  /// Takes what the row becomes, and the code the exchange returned.
  const UseSmileIDSampleStatusUpdated({
    required this.status,
    required this.message,
    required this.httpCode,
  });

  /// The verdict the row takes.
  final UseSmileIDSampleStatus status;

  /// The server's own words.
  final String message;

  /// The code the exchange returned.
  final int httpCode;
}

/// 202 — still running; the row already says Processing.
class UseSmileIDSampleStatusStillProcessing
    extends UseSmileIDSampleStatusRefresh {
  /// No fields: the row is already saying this.
  const UseSmileIDSampleStatusStillProcessing();
}

/// 404 — the server has no state for the job yet. The store reads it as still processing while the job is new, and as a failure after that.
class UseSmileIDSampleStatusNotRecorded extends UseSmileIDSampleStatusRefresh {
  /// No fields: the code is the whole message.
  const UseSmileIDSampleStatusNotRecorded();
}

/// No live session, so no credential to ask with. A precondition, not an error.
class UseSmileIDSampleStatusNoSession extends UseSmileIDSampleStatusRefresh {
  /// No fields: which session is missing is not the screen's business.
  const UseSmileIDSampleStatusNoSession();
}

/// Never submitted under a scanned session, so there is no server-side job.
class UseSmileIDSampleStatusNoServerJob extends UseSmileIDSampleStatusRefresh {
  /// No fields: the row's own null session id is the whole reason.
  const UseSmileIDSampleStatusNoServerJob();
}

/// Submitted by a different partner, so this session's credential is for another account.
class UseSmileIDSampleStatusPartnerMismatch
    extends UseSmileIDSampleStatusRefresh {
  /// No fields: naming the other partner would publish an id this app does not own.
  const UseSmileIDSampleStatusPartnerMismatch();
}

/// The refresh could not complete, with what to say about it.
@immutable
class UseSmileIDSampleStatusFailed extends UseSmileIDSampleStatusRefresh {
  /// [reason] is the server's own wording, such as an HTTP code, shown as it came.
  const UseSmileIDSampleStatusFailed(String this.reason) : _kind = null;

  /// The row was deleted while the request was out.
  const UseSmileIDSampleStatusFailed.notStored()
    : reason = null,
      _kind = _Failure.notStored;

  /// Anything else; [type] is the error's type, never its message, which carries the URL.
  const UseSmileIDSampleStatusFailed.unexpected(String type)
    : reason = type,
      _kind = _Failure.unexpected;

  /// The server's wording, or the error type for [UseSmileIDSampleStatusFailed.unexpected].
  final String? reason;
  final _Failure? _kind;

  /// What the screen says happened, in the app's language.
  String message(UseSmileIDSampleStrings strings) => switch (_kind) {
    _Failure.notStored => strings.jobErrorNotStored,
    _Failure.unexpected => strings.jobErrorUnexpected(type: reason ?? ''),
    null => reason ?? '',
  };

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleStatusFailed &&
      other.reason == reason &&
      other._kind == _kind;

  @override
  int get hashCode => Object.hash(reason, _kind);
}

enum _Failure { notStored, unexpected }

/// A live token session, as much of it as a refresh needs to decide whether it may ask.
@immutable
class UseSmileIDSampleRefreshSession {
  /// Takes the credential, the partner it was minted for, and when it runs out.
  const UseSmileIDSampleRefreshSession({
    required this.token,
    required this.partnerId,
    required this.expiresAtMillis,
  });

  /// The credential a refresh asks with.
  final String token;

  /// The partner the token was minted for, which is what a row is matched against.
  final String? partnerId;

  /// When the session runs out.
  final int expiresAtMillis;
}

/// Maps the HTTP exchange onto an outcome and lets a transport failure throw — the store owns reporting it.
abstract interface class UseSmileIDSampleJobStatusSource {
  /// Asks the server what became of [jobId], under [token] and the row's own environment.
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  });
}

/// What each outcome says on screen, in Android's words.
String useSmileIDSampleRefreshLabel(
  UseSmileIDSampleStatusRefresh outcome,
  UseSmileIDSampleStrings strings,
) => switch (outcome) {
  final UseSmileIDSampleStatusUpdated updated => strings.statusRefreshResult(
    status: updated.status.label(strings),
    message: updated.message,
  ),
  UseSmileIDSampleStatusStillProcessing() => strings.statusRefreshProcessing,
  UseSmileIDSampleStatusNotRecorded() => strings.statusRefreshFailed(
    reason: useSmileIDSampleNotRecordedDetail,
  ),
  UseSmileIDSampleStatusNoSession() => strings.statusRefreshNoSession,
  UseSmileIDSampleStatusNoServerJob() => strings.statusRefreshNotTokenJob,
  UseSmileIDSampleStatusPartnerMismatch() => strings.statusRefreshOtherPartner,
  final UseSmileIDSampleStatusFailed failed => strings.statusRefreshFailed(
    reason: failed.message(strings),
  ),
};

/// How long a 404 reads as a job the server has not recorded yet; after it, as a job it never will.
const int useSmileIDSampleNotRecordedWindowMillis = 10 * 60 * 1000;

/// What a job the server never recorded reads as: the code it answered with.
const String useSmileIDSampleNotRecordedDetail = 'HTTP 404';

/// The wait before the list's next check of rows still processing, backing off from 5s to a minute; null once it has asked enough.
Duration? useSmileIDSampleProcessingPollDelay(int attempt) {
  if (attempt >= 12) {
    return null;
  }
  final int seconds = 5 * (1 << (attempt < 4 ? attempt : 4));
  return Duration(seconds: seconds < 60 ? seconds : 60);
}
