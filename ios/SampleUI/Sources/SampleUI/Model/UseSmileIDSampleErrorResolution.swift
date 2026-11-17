/// What a failed verification offers the user; the raw value is its id in `spec/error-handling.json`.
public enum UseSmileIDSampleErrorAction: String, CaseIterable, Sendable {
  case retry
  case retryLater
  case recapture
  case fixInput
  case newSession
  case exit

  /// The button's key in `spec/l10n/app/`.
  public var buttonKey: String {
    switch self {
    case .retry, .retryLater: "common_try_again"
    case .recapture: "error_action_retake_photo"
    case .fixInput: "error_action_edit_id_number"
    case .newSession: "error_action_start_again"
    case .exit: "error_action_close"
    }
  }

  /// How many times the action is offered; nil is no limit.
  public var maxUses: Int? {
    switch self {
    case .recapture: 3
    case .newSession: 1
    case .retry, .retryLater, .fixInput, .exit: nil
    }
  }
}

/// The message a failure shows; the raw value is its key in `spec/l10n/app/`.
public enum UseSmileIDSampleErrorMessage: String, CaseIterable, Sendable {
  case couldNotStart = "error_could_not_start"
  case idNumberInvalid = "error_id_number_invalid"
  case serviceNotSetUp = "error_service_not_set_up"
  case sessionExpired = "error_session_expired"
  case serviceUnavailable = "error_service_unavailable"
  case notAvailable = "error_not_available"
  case updateApp = "error_update_app"
  case notFound = "error_not_found"
  case alreadyStarted = "error_already_started"
  case linkExpired = "error_link_expired"
  case photosTooLarge = "error_photos_too_large"
  case tooManyAttempts = "error_too_many_attempts"
  case server = "error_server"
  case noConnection = "error_no_connection"
  case timeout = "error_timeout"
  case photoUnusable = "error_photo_unusable"
  case photoRejected = "error_photo_rejected"
  case documentNotRecognised = "error_document_not_recognised"
  case faceCheckUnavailable = "error_face_check_unavailable"
  case noSavedSelfie = "error_no_saved_selfie"
  case idNumberNotAccepted = "error_id_number_not_accepted"
  case idServiceDown = "error_id_service_down"
  case couldNotFinish = "error_could_not_finish"
  case notVerified = "error_not_verified"
}

/// A submission the server never answered; the raw value is its id in `spec/error-handling.json`.
public enum UseSmileIDSampleTransportFailure: String, CaseIterable, Sendable {
  case noConnection
  case timeout
}

/// What a failure resolves to: the message to show and the one action to offer.
public struct UseSmileIDSampleErrorResolution: Equatable, Sendable {
  public let id: String
  public let message: UseSmileIDSampleErrorMessage
  public let action: UseSmileIDSampleErrorAction
  /// How long the button stays dimmed before each use, in order.
  public let backoffSeconds: [Int]
  /// How many times the action is offered before Close replaces it; nil is no limit.
  public let maxUses: Int?
  /// Whether the button also stays dimmed while the device is offline.
  public let waitsForConnection: Bool

  init(
    _ id: String,
    _ message: UseSmileIDSampleErrorMessage,
    _ action: UseSmileIDSampleErrorAction,
    backoffSeconds: [Int] = [],
    maxUses: Int? = nil,
    waitsForConnection: Bool = false
  ) {
    self.id = id
    self.message = message
    self.action = action
    self.backoffSeconds = backoffSeconds
    self.maxUses = maxUses ?? action.maxUses
    self.waitsForConnection = waitsForConnection
  }
}
