import Foundation

/// What verification details states: a stored job's `error` or `block`, or with no job the failed run that landed here.
public func useSmileIDSampleDetailsFailure(
  job: UseSmileIDSampleJob?,
  landedRun: UseSmileIDSampleErrorResolution?
) -> UseSmileIDSampleErrorResolution? {
  guard let job else { return landedRun }
  // The status endpoint returns no reason yet, so every such job resolves as the fallback.
  return job.status == .error || job.status == .blocked ? UseSmileIDSampleErrorHandling.forReason(nil) : nil
}

/// What a run that landed with no job states: its row, or the submission fallback when no submission explained the failure.
public func useSmileIDSampleLandedFailure(
  status: UseSmileIDSampleFlowStatus,
  row: UseSmileIDSampleErrorResolution?
) -> UseSmileIDSampleErrorResolution? {
  status == .failed ? row ?? UseSmileIDSampleErrorHandling.submissionFallback : nil
}

public extension UseSmileIDSampleErrorResolution {
  /// Warning while the user can act on the failure, error once Close is all it offers.
  var bannerTone: UseSmileIDSampleBannerTone {
    action == .exit ? .error : .warning
  }

  /// Whether the banner shows its button: on a stored job the app bar's back already closes the screen.
  func offersAction(onStoredJob: Bool) -> Bool {
    !(onStoredJob && action == .exit)
  }
}

public extension UseSmileIDSampleErrorMessage {
  /// The message in the app's language.
  var text: String {
    switch self {
    case .couldNotStart: UseSmileIDSampleStrings.errorCouldNotStart
    case .idNumberInvalid: UseSmileIDSampleStrings.errorIdNumberInvalid
    case .serviceNotSetUp: UseSmileIDSampleStrings.errorServiceNotSetUp
    case .sessionExpired: UseSmileIDSampleStrings.errorSessionExpired
    case .serviceUnavailable: UseSmileIDSampleStrings.errorServiceUnavailable
    case .notAvailable: UseSmileIDSampleStrings.errorNotAvailable
    case .updateApp: UseSmileIDSampleStrings.errorUpdateApp
    case .notFound: UseSmileIDSampleStrings.errorNotFound
    case .alreadyStarted: UseSmileIDSampleStrings.errorAlreadyStarted
    case .linkExpired: UseSmileIDSampleStrings.errorLinkExpired
    case .photosTooLarge: UseSmileIDSampleStrings.errorPhotosTooLarge
    case .tooManyAttempts: UseSmileIDSampleStrings.errorTooManyAttempts
    case .server: UseSmileIDSampleStrings.errorServer
    case .noConnection: UseSmileIDSampleStrings.errorNoConnection
    case .timeout: UseSmileIDSampleStrings.errorTimeout
    case .photoUnusable: UseSmileIDSampleStrings.errorPhotoUnusable
    case .photoRejected: UseSmileIDSampleStrings.errorPhotoRejected
    case .documentNotRecognised: UseSmileIDSampleStrings.errorDocumentNotRecognised
    case .faceCheckUnavailable: UseSmileIDSampleStrings.errorFaceCheckUnavailable
    case .noSavedSelfie: UseSmileIDSampleStrings.errorNoSavedSelfie
    case .idNumberNotAccepted: UseSmileIDSampleStrings.errorIdNumberNotAccepted
    case .idServiceDown: UseSmileIDSampleStrings.errorIdServiceDown
    case .couldNotFinish: UseSmileIDSampleStrings.errorCouldNotFinish
    case .notVerified: UseSmileIDSampleStrings.errorNotVerified
    }
  }
}

public extension UseSmileIDSampleErrorAction {
  /// The label on the failure's one button.
  var label: String {
    switch self {
    case .retry, .retryLater: UseSmileIDSampleStrings.commonTryAgain
    case .recapture: UseSmileIDSampleStrings.errorActionRetakePhoto
    case .fixInput: UseSmileIDSampleStrings.errorActionEditIdNumber
    case .newSession: UseSmileIDSampleStrings.errorActionStartAgain
    case .exit: UseSmileIDSampleStrings.errorActionClose
    }
  }
}
