/// What a failed verification offers the user; `name` is its id in `spec/error-handling.json`.
enum UseSmileIDSampleErrorAction {
  /// Runs the verification again as a new job.
  retry('common_try_again'),

  /// As [retry], with a longer delay and a single use.
  retryLater('common_try_again'),

  /// Restarts capture, then submits a new job.
  recapture('error_action_retake_photo', maxUses: 3),

  /// Returns to the ID form.
  fixInput('error_action_edit_id_number'),

  /// Takes a new token and restarts the flow.
  newSession('error_action_start_again', maxUses: 1),

  /// Ends the flow.
  exit('error_action_close');

  const UseSmileIDSampleErrorAction(this.buttonKey, {this.maxUses});

  /// The button's key in `spec/l10n/app/`.
  final String buttonKey;

  /// How many times the action is offered; null is no limit.
  final int? maxUses;
}

/// The message a failure shows, by its key in `spec/l10n/app/`.
enum UseSmileIDSampleErrorMessage {
  /// The request was refused before it could start.
  couldNotStart('error_could_not_start'),

  /// A failed run no row explains: it stopped before it finished.
  endedEarly('error_ended_early'),

  /// The ID number was refused at submission.
  idNumberInvalid('error_id_number_invalid'),

  /// The partner has no callback URL.
  serviceNotSetUp('error_service_not_set_up'),

  /// The token is no longer accepted.
  sessionExpired('error_session_expired'),

  /// The partner cannot run a job at the moment.
  serviceUnavailable('error_service_unavailable'),

  /// The verification is not enabled or not allowed.
  notAvailable('error_not_available'),

  /// The SDK version is no longer allowed.
  updateApp('error_update_app'),

  /// The job, link or user was not found.
  notFound('error_not_found'),

  /// The user ID or link is already in use.
  alreadyStarted('error_already_started'),

  /// The link has expired.
  linkExpired('error_link_expired'),

  /// The submission was too large.
  photosTooLarge('error_photos_too_large'),

  /// The rate limit was reached.
  tooManyAttempts('error_too_many_attempts'),

  /// The server failed.
  server('error_server'),

  /// The device has no connection.
  noConnection('error_no_connection'),

  /// The request timed out.
  timeout('error_timeout'),

  /// A photo could not be used.
  photoUnusable('error_photo_unusable'),

  /// A photo was refused.
  photoRejected('error_photo_rejected'),

  /// The document could not be classified.
  documentNotRecognised('error_document_not_recognised'),

  /// The ID authority holds no photo to compare.
  faceCheckUnavailable('error_face_check_unavailable'),

  /// The user has no enrolled selfie.
  noSavedSelfie('error_no_saved_selfie'),

  /// The ID number was refused after the job was accepted.
  idNumberNotAccepted('error_id_number_not_accepted'),

  /// The ID authority is unavailable.
  idServiceDown('error_id_service_down'),

  /// The job failed for a reason of the server's own.
  couldNotFinish('error_could_not_finish'),

  /// The one message every fraud and compliance outcome shows.
  notVerified('error_not_verified');

  const UseSmileIDSampleErrorMessage(this.key);

  /// The message's key in `spec/l10n/app/`.
  final String key;
}

/// A submission the server never answered; `name` is its id in `spec/error-handling.json`.
enum UseSmileIDSampleTransportFailure {
  /// The device could not reach the server.
  noConnection,

  /// The request took too long.
  timeout,
}

/// What a failure resolves to: the message to show and the one action to offer.
final class UseSmileIDSampleErrorResolution {
  /// A row's resolution; [maxUses] falls back to the action's.
  const UseSmileIDSampleErrorResolution(
    this.id,
    this.message,
    this.action, {
    this.backoffSeconds = const <int>[],
    int? maxUses,
    this.waitsForConnection = false,
  }) : _maxUses = maxUses;

  /// The row's id in `spec/error-handling.json`.
  final String id;

  /// The message to show.
  final UseSmileIDSampleErrorMessage message;

  /// The one action to offer.
  final UseSmileIDSampleErrorAction action;

  /// How long the button stays dimmed before each use, in order.
  final List<int> backoffSeconds;

  /// Whether the button also stays dimmed while the device is offline.
  final bool waitsForConnection;

  final int? _maxUses;

  /// How many times the action is offered before Close replaces it; null is no limit.
  int? get maxUses => _maxUses ?? action.maxUses;
}
