import '../model/use_smileid_sample_error_resolution.dart';

/// The table in `spec/error-handling.json`: rows are tried in order and the first match wins.
abstract final class UseSmileIDSampleErrorHandling {
  // What a status or transport failure the table does not name resolves as.
  static const _Resolution _requestInvalid = _Resolution(
    'requestInvalid',
    _Message.couldNotStart,
    _Action.exit,
  );

  // What a reason the table does not name resolves as.
  static const _Resolution _notVerified = _Resolution(
    'notVerified',
    _Message.notVerified,
    _Action.exit,
  );

  static const List<_Row> _submissionRows = <_Row>[
    _Row(
      _Resolution(
        'idNumberInvalid',
        _Message.idNumberInvalid,
        _Action.fixInput,
      ),
      statuses: <int>[400],
      serverMessageContains: <String>[
        'id number format',
        'id_number',
        'id_type',
      ],
    ),
    _Row(
      _Resolution('callbackUrlMissing', _Message.serviceNotSetUp, _Action.exit),
      statuses: <int>[400],
      serverMessageContains: <String>['callback'],
    ),
    _Row(_requestInvalid, statuses: <int>[400]),
    _Row(
      _Resolution(
        'sessionExpired',
        _Message.sessionExpired,
        _Action.newSession,
      ),
      statuses: <int>[401],
    ),
    _Row(
      _Resolution(
        'insufficientBalance',
        _Message.serviceUnavailable,
        _Action.exit,
      ),
      statuses: <int>[402],
    ),
    _Row(
      _Resolution('sdkVersionNotAllowed', _Message.updateApp, _Action.exit),
      statuses: <int>[403],
      serverMessageContains: <String>['sdk version'],
    ),
    _Row(
      _Resolution('notEnabled', _Message.notAvailable, _Action.exit),
      statuses: <int>[403],
    ),
    _Row(
      _Resolution('notFound', _Message.notFound, _Action.exit),
      statuses: <int>[404],
    ),
    _Row(
      _Resolution(
        'alreadyStarted',
        _Message.alreadyStarted,
        _Action.newSession,
      ),
      statuses: <int>[409],
    ),
    _Row(
      _Resolution('linkExpired', _Message.linkExpired, _Action.exit),
      statuses: <int>[410],
    ),
    _Row(
      _Resolution(
        'payloadTooLarge',
        _Message.photosTooLarge,
        _Action.recapture,
      ),
      statuses: <int>[413],
    ),
    _Row(
      _Resolution('wrongContentType', _Message.couldNotStart, _Action.exit),
      statuses: <int>[415],
    ),
    _Row(
      _Resolution(
        'tokenPayloadInvalid',
        _Message.sessionExpired,
        _Action.newSession,
      ),
      statuses: <int>[422],
    ),
    _Row(
      _Resolution(
        'rateLimited',
        _Message.tooManyAttempts,
        _Action.retry,
        backoffSeconds: <int>[30],
        maxUses: 1,
      ),
      statuses: <int>[429],
    ),
    _Row(
      _Resolution(
        'serverError',
        _Message.server,
        _Action.retry,
        backoffSeconds: <int>[5, 15, 30],
        maxUses: 3,
      ),
      statuses: <int>[500, 502, 503, 504],
    ),
    _Row(
      _Resolution(
        'noConnection',
        _Message.noConnection,
        _Action.retry,
        waitsForConnection: true,
      ),
      transport: UseSmileIDSampleTransportFailure.noConnection,
    ),
    _Row(
      _Resolution(
        'timeout',
        _Message.timeout,
        _Action.retry,
        backoffSeconds: <int>[5],
      ),
      transport: UseSmileIDSampleTransportFailure.timeout,
    ),
  ];

  static const List<_Row> _resultRows = <_Row>[
    _Row(
      _Resolution(
        'idAuthorityPhotoUnavailable',
        _Message.faceCheckUnavailable,
        _Action.exit,
      ),
      reasons: <String>['image_unavailable_or_invalid'],
      serverMessageContains: <String>['id authority photo not available'],
    ),
    _Row(
      _Resolution('noEnrolledSelfie', _Message.noSavedSelfie, _Action.exit),
      reasons: <String>['image_unavailable_or_invalid'],
      serverMessageContains: <String>['no enrolled selfie found'],
    ),
    _Row(
      _Resolution('photoUnusable', _Message.photoUnusable, _Action.recapture),
      reasons: <String>['image_unavailable_or_invalid'],
    ),
    _Row(
      _Resolution(
        'contentPolicyViolated',
        _Message.photoRejected,
        _Action.recapture,
      ),
      reasons: <String>['content_policy_violated'],
    ),
    _Row(
      _Resolution(
        'documentUnclassifiable',
        _Message.documentNotRecognised,
        _Action.recapture,
      ),
      reasons: <String>['document_unclassifiable'],
    ),
    _Row(
      _Resolution(
        'invalidIdNumber',
        _Message.idNumberNotAccepted,
        _Action.fixInput,
      ),
      reasons: <String>['invalid_id_number'],
    ),
    _Row(
      _Resolution(
        'serviceUnavailable',
        _Message.idServiceDown,
        _Action.retryLater,
        backoffSeconds: <int>[30],
        maxUses: 1,
      ),
      reasons: <String>['service_unavailable'],
    ),
    _Row(
      _Resolution(
        'internalError',
        _Message.couldNotFinish,
        _Action.retry,
        backoffSeconds: <int>[5],
        maxUses: 1,
      ),
      reasons: <String>['internal_error'],
    ),
    _Row(
      _notVerified,
      reasons: <String>[
        'spoof_detected',
        'face_verification_failed',
        'document_check_failed',
        'age_requirement_not_met',
        'account_locked',
        'account_locked_fraud',
        'high_risk',
        'medium_risk',
        'identifier_not_found',
      ],
    ),
  ];

  /// Every submission row's resolution, in the table's order.
  static final List<UseSmileIDSampleErrorResolution> submission =
      List<UseSmileIDSampleErrorResolution>.unmodifiable(
        _submissionRows.map((_Row row) => row.resolution),
      );

  /// Every result row's resolution, in the table's order.
  static final List<UseSmileIDSampleErrorResolution> result =
      List<UseSmileIDSampleErrorResolution>.unmodifiable(
        _resultRows.map((_Row row) => row.resolution),
      );

  /// The row a submission the table does not name resolves as.
  static UseSmileIDSampleErrorResolution get submissionFallback =>
      _requestInvalid;

  /// A submission the server refused with [status]; [serverMessage] only tells rows apart and is never shown.
  static UseSmileIDSampleErrorResolution forStatus(
    int status, {
    String? serverMessage,
  }) => _resolve(
    _submissionRows.where((_Row row) => row.statuses.contains(status)),
    serverMessage,
    _requestInvalid,
  );

  /// A submission the server never answered.
  static UseSmileIDSampleErrorResolution forTransport(
    UseSmileIDSampleTransportFailure failure,
  ) => _resolve(
    _submissionRows.where((_Row row) => row.transport == failure),
    null,
    _requestInvalid,
  );

  /// An accepted job that ended in `error` or `block` with [reason]; none, or one the table does not name, is never explained.
  static UseSmileIDSampleErrorResolution forReason(
    String? reason, {
    String? serverMessage,
  }) => _resolve(
    _resultRows.where((_Row row) => row.reasons.contains(reason)),
    serverMessage,
    _notVerified,
  );

  static UseSmileIDSampleErrorResolution _resolve(
    Iterable<_Row> candidates,
    String? serverMessage,
    UseSmileIDSampleErrorResolution fallback,
  ) {
    for (final _Row row in candidates) {
      if (row.accepts(serverMessage)) return row.resolution;
    }
    return fallback;
  }
}

typedef _Resolution = UseSmileIDSampleErrorResolution;
typedef _Message = UseSmileIDSampleErrorMessage;
typedef _Action = UseSmileIDSampleErrorAction;

/// One row: a resolution and what a failure must carry to match it.
final class _Row {
  const _Row(
    this.resolution, {
    this.statuses = const <int>[],
    this.transport,
    this.reasons = const <String>[],
    this.serverMessageContains = const <String>[],
  });

  final UseSmileIDSampleErrorResolution resolution;
  final List<int> statuses;
  final UseSmileIDSampleTransportFailure? transport;
  final List<String> reasons;
  final List<String> serverMessageContains;

  bool accepts(String? serverMessage) {
    if (serverMessageContains.isEmpty) return true;
    final String text = (serverMessage ?? '').toLowerCase();
    return serverMessageContains.any(text.contains);
  }
}
