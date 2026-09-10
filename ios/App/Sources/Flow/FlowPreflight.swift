import SampleUI
import UseSmileID

/// What the gate decided, and so where the journey goes instead of the SDK.
enum FlowPreflight: Equatable {
  case ready
  /// The forms can resolve it.
  case needsDetails(issues: [String])
  /// Only a new token resolves it, so the journey goes back to the scanner rather than to a form.
  case needsSession
  /// No form can resolve it, and it must still never reach the SDK.
  case misconfigured(issues: [String])
}

/// The entry gate: the SDK's own validators through `FlowValidator.shared`, before anything mounts. No consent rule, level with the Compose twin.
@MainActor
func useSmileIDSamplePreflight(_ snapshot: FlowLaunchSnapshot) -> FlowPreflight {
  // Ahead of the payloads: no form fixes a session that has run out.
  if snapshot.sessionExpired {
    return .needsSession
  }
  let validator = FlowValidator.shared
  let requirement = UseSmileIDSampleUserDetailsRequirement(bindings: snapshot.liveSession?.bindings)
  let params = useSmileIDSampleIdParams(snapshot)
  var payloadChecks: [ValidationState] = []
  // The token-payload overload is not public, so the bindings are subtracted from what the SDK reports.
  if let userDetails = useSmileIDSampleUserDetails(snapshot) {
    payloadChecks.append(useSmileIDSampleOutstanding(validator.validateUserDetails(userDetails), requirement))
  }
  if let biometricKyc = params.biometricKyc {
    payloadChecks.append(validator.validateBiometricKYCParams(biometricKyc))
  }
  if let enhancedKyc = params.enhancedKyc {
    payloadChecks.append(validator.validateEnhancedKYCParams(enhancedKyc))
  }
  if let documentVerification = params.documentVerification {
    payloadChecks.append(validator.validateDocumentVerificationParams(documentVerification))
  }
  if let enhancedDocumentVerification = params.enhancedDocumentVerification {
    payloadChecks.append(validator.validateEnhancedDocumentVerificationParams(enhancedDocumentVerification))
  }
  let payloadIssues = payloadChecks.flatMap(\.errors)
  if !payloadIssues.isEmpty {
    return .needsDetails(issues: payloadIssues.map(\.useSmileIDSampleReason))
  }
  // The structural list the SDK applies when it renders; warnings do not block a run.
  let structural = validator
    .validate(configuration: useSmileIDSampleConfiguration(snapshot, params: params))
    .errors
  return structural.isEmpty ? .ready : .misconfigured(issues: structural.map(\.useSmileIDSampleReason))
}

/// The run's own screens and payloads; building the default client once per entry is the cost of the only public shape.
@MainActor
private func useSmileIDSampleConfiguration(_ snapshot: FlowLaunchSnapshot, params: FlowIdParams) -> FlowConfiguration {
  FlowConfiguration(
    screens: useSmileIDSampleFlowSteps(snapshot),
    jobType: snapshot.product.jobType,
    userDetails: useSmileIDSampleUserDetails(snapshot),
    userId: snapshot.product == .smartSelfieAuth ? snapshot.userId : nil,
    enhancedKYCParams: params.enhancedKyc,
    biometricKYCParams: params.biometricKyc,
    documentVerificationParams: params.documentVerification,
    enhancedDocumentVerificationParams: params.enhancedDocumentVerification
  )
}

extension UseSmileIDValidationException {
  /// Strings, not exceptions, so nothing that renders a run imports the SDK.
  var useSmileIDSampleReason: String {
    message.isEmpty ? String(describing: type(of: self)) : message
  }
}
