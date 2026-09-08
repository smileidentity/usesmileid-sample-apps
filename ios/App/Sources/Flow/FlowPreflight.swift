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

/// The entry gate: the SDK's own validators, before anything mounts.
///
/// Through `FlowValidator.shared` rather than a builder, unlike the Compose twin:
/// `UseSmileIDFlowBuilder` has no public initialiser at 12.0.2, so a host reaches it only inside
/// `UseSmileIDBuilder`'s closure — by which point the SDK has mounted.
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
  // The SDK does the validating; its token-payload overload is not public, so the bindings are
  // subtracted from what it reports.
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
  // The SDK's own rule, stated here because the overload enforcing it needs a token payload no
  // public call can pass — asking the validator would block every consent-bound run.
  if !useSmileIDSampleJourneySteps(snapshot).contains(.consent), snapshot.liveSession?.bindings.consent == nil {
    return .misconfigured(issues: [noConsentReason])
  }
  // The same structural list the SDK applies when it renders. Warnings do not block a run: a missing
  // ML or network block reads as one, and this host passes both.
  let structural = validator
    .validate(configuration: useSmileIDSampleConfiguration(snapshot, params: params))
    .errors
  return structural.isEmpty ? .ready : .misconfigured(issues: structural.map(\.useSmileIDSampleReason))
}

/// The SDK's own words, so a flow keys off the sentence it would have delivered as a failure.
private let noConsentReason = "must include either a Consent screen or a pre-supplied consentInformation"

/// The run's own screens and payloads. The ML and network defaults go unread by this overload, and
/// building the default client once per entry is the cost of the only public shape.
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
