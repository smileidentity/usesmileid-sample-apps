import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_status.dart';

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
  /// [reason] goes on screen, so it never carries an exception's message.
  const UseSmileIDSampleStatusFailed(this.reason);

  /// What the screen says happened.
  final String reason;
}

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
) => switch (outcome) {
  final UseSmileIDSampleStatusUpdated updated =>
    '${updated.status.label} — ${updated.message}',
  UseSmileIDSampleStatusStillProcessing() => 'Still processing',
  UseSmileIDSampleStatusNoSession() => 'Scan a token first',
  UseSmileIDSampleStatusNoServerJob() => 'Not submitted under a scanned token',
  UseSmileIDSampleStatusPartnerMismatch() => 'Submitted by a different partner',
  final UseSmileIDSampleStatusFailed failed =>
    'Could not check status: ${failed.reason}',
};
