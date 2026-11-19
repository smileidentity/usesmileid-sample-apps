import Foundation

/// The table in `spec/error-handling.json`: rows are tried in order and the first match wins.
public enum UseSmileIDSampleErrorHandling {
  /// What a status or transport failure the table does not name resolves as.
  private static let requestInvalid = UseSmileIDSampleErrorResolution("requestInvalid", .couldNotStart, .exit)

  /// What a reason the table does not name resolves as.
  private static let notVerified = UseSmileIDSampleErrorResolution("notVerified", .notVerified, .exit)

  private static let submissionRows: [Row] = [
    Row(.init("idNumberInvalid", .idNumberInvalid, .fixInput), statuses: [400], serverMessageContains: ["id number format", "id_number", "id_type"]),
    Row(.init("callbackUrlMissing", .serviceNotSetUp, .exit), statuses: [400], serverMessageContains: ["callback"]),
    Row(requestInvalid, statuses: [400]),
    Row(.init("sessionExpired", .sessionExpired, .newSession), statuses: [401]),
    Row(.init("insufficientBalance", .serviceUnavailable, .exit), statuses: [402]),
    Row(.init("sdkVersionNotAllowed", .updateApp, .exit), statuses: [403], serverMessageContains: ["sdk version"]),
    Row(.init("notEnabled", .notAvailable, .exit), statuses: [403]),
    Row(.init("notFound", .notFound, .exit), statuses: [404]),
    Row(.init("alreadyStarted", .alreadyStarted, .newSession), statuses: [409]),
    Row(.init("linkExpired", .linkExpired, .exit), statuses: [410]),
    Row(.init("payloadTooLarge", .photosTooLarge, .recapture), statuses: [413]),
    Row(.init("wrongContentType", .couldNotStart, .exit), statuses: [415]),
    Row(.init("tokenPayloadInvalid", .sessionExpired, .newSession), statuses: [422]),
    Row(.init("rateLimited", .tooManyAttempts, .retry, backoffSeconds: [30], maxUses: 1), statuses: [429]),
    Row(.init("serverError", .server, .retry, backoffSeconds: [5, 15, 30], maxUses: 3), statuses: [500, 502, 503, 504]),
    Row(.init("noConnection", .noConnection, .retry, waitsForConnection: true), transport: .noConnection),
    Row(.init("timeout", .timeout, .retry, backoffSeconds: [5]), transport: .timeout)
  ]

  private static let resultRows: [Row] = [
    Row(
      .init("idAuthorityPhotoUnavailable", .faceCheckUnavailable, .exit),
      reasons: ["image_unavailable_or_invalid"],
      serverMessageContains: ["id authority photo not available"]
    ),
    Row(.init("noEnrolledSelfie", .noSavedSelfie, .exit), reasons: ["image_unavailable_or_invalid"], serverMessageContains: ["no enrolled selfie found"]),
    Row(.init("photoUnusable", .photoUnusable, .recapture), reasons: ["image_unavailable_or_invalid"]),
    Row(.init("contentPolicyViolated", .photoRejected, .recapture), reasons: ["content_policy_violated"]),
    Row(.init("documentUnclassifiable", .documentNotRecognised, .recapture), reasons: ["document_unclassifiable"]),
    Row(.init("invalidIdNumber", .idNumberNotAccepted, .fixInput), reasons: ["invalid_id_number"]),
    Row(.init("serviceUnavailable", .idServiceDown, .retryLater, backoffSeconds: [30], maxUses: 1), reasons: ["service_unavailable"]),
    Row(.init("internalError", .couldNotFinish, .retry, backoffSeconds: [5], maxUses: 1), reasons: ["internal_error"]),
    Row(
      notVerified,
      reasons: [
        "spoof_detected", "face_verification_failed", "document_check_failed", "age_requirement_not_met", "account_locked",
        "account_locked_fraud", "high_risk", "medium_risk", "identifier_not_found"
      ]
    )
  ]

  /// Every submission row's resolution, in the table's order.
  public static let submission: [UseSmileIDSampleErrorResolution] = submissionRows.map(\.resolution)

  /// Every result row's resolution, in the table's order.
  public static let result: [UseSmileIDSampleErrorResolution] = resultRows.map(\.resolution)

  /// What a failed run no row explains resolves as: it says only that the run stopped before it finished.
  public static let unexplained = UseSmileIDSampleErrorResolution("endedEarly", .endedEarly, .retry)

  /// The row a saved `id` names; nil for none, or for one this build no longer has.
  public static func resolution(id: String?) -> UseSmileIDSampleErrorResolution? {
    (submission + result + [unexplained]).first { $0.id == id }
  }

  /// A submission the server refused with `status`; `serverMessage` only tells rows apart and is never shown.
  public static func forStatus(_ status: Int, serverMessage: String? = nil) -> UseSmileIDSampleErrorResolution {
    submissionRows.first { $0.statuses.contains(status) && $0.accepts(serverMessage) }?.resolution ?? requestInvalid
  }

  /// A submission the server never answered.
  public static func forTransport(_ failure: UseSmileIDSampleTransportFailure) -> UseSmileIDSampleErrorResolution {
    submissionRows.first { $0.transport == failure }?.resolution ?? requestInvalid
  }

  /// An accepted job that ended in `error` or `block` with `reason`; none, or one the table does not name, is never explained.
  public static func forReason(_ reason: String?, serverMessage: String? = nil) -> UseSmileIDSampleErrorResolution {
    guard let reason else { return notVerified }
    return resultRows.first { $0.reasons.contains(reason) && $0.accepts(serverMessage) }?.resolution ?? notVerified
  }
}

/// One row: a resolution and what a failure must carry to match it.
private struct Row {
  let resolution: UseSmileIDSampleErrorResolution
  let statuses: [Int]
  let transport: UseSmileIDSampleTransportFailure?
  let reasons: [String]
  let serverMessageContains: [String]

  init(
    _ resolution: UseSmileIDSampleErrorResolution,
    statuses: [Int] = [],
    transport: UseSmileIDSampleTransportFailure? = nil,
    reasons: [String] = [],
    serverMessageContains: [String] = []
  ) {
    self.resolution = resolution
    self.statuses = statuses
    self.transport = transport
    self.reasons = reasons
    self.serverMessageContains = serverMessageContains
  }

  func accepts(_ serverMessage: String?) -> Bool {
    guard !serverMessageContains.isEmpty else { return true }
    guard let serverMessage else { return false }
    return serverMessageContains.contains { serverMessage.range(of: $0, options: .caseInsensitive) != nil }
  }
}
