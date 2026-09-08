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

/// §7.3's entry gate: the SDK's non-throwing pre-flight plus its per-payload validators.
///
/// Through `FlowValidator.shared` rather than a builder, unlike the Compose twin:
/// `UseSmileIDFlowBuilder` has no public initialiser at 12.0.2, so a host can only reach it inside
/// `UseSmileIDBuilder`'s own closure — by which point the SDK has already mounted. The validator is
/// the same object the builder's `validate()` calls, given the screens and payloads the run composes.
@MainActor
func useSmileIDSamplePreflight(_ snapshot: FlowLaunchSnapshot) -> FlowPreflight {
  // Ahead of the payloads, because no form fixes a session that has run out.
  if snapshot.sessionExpired {
    return .needsSession
  }
  let validator = FlowValidator.shared
  // A form can fix what the user typed but not how the host built the flow, and §7.3 redirects only
  // the first.
  let requirement = UseSmileIDSampleUserDetailsRequirement(bindings: snapshot.liveSession?.bindings)
  let params = useSmileIDSampleIdParams(snapshot)
  var payloadChecks: [ValidationState] = []
  // The SDK still does the validating — its overload that takes a token payload is not public API at
  // 12.0.2, so the bindings are subtracted from what it reports instead.
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
  // Every job type needs consent, from a screen or from the token. The SDK's own rule, stated here
  // rather than read off the validator: the overload that enforces it takes a decoded token payload,
  // and that parameter is not public at 12.0.2, so asking the validator would block every run a
  // token's consent claim covers. The host decides both halves of this anyway.
  if !useSmileIDSampleJourneySteps(snapshot).contains(.consent), snapshot.liveSession?.bindings.consent == nil {
    return .misconfigured(issues: [noConsentReason])
  }
  // The structural rules — empty screens, per-screen configuration, duplicates, ordering, preview
  // count — which is the same list the SDK applies when it renders. Warnings alone do not block a
  // run: a missing ML or network block reads as one, and this host always passes both.
  let structural = validator
    .validate(configuration: useSmileIDSampleConfiguration(snapshot, params: params))
    .errors
  return structural.isEmpty ? .ready : .misconfigured(issues: structural.map(\.useSmileIDSampleReason))
}

/// The SDK's own words for the rule above, so a flow keys off the same sentence the SDK would have
/// delivered as a failure.
private let noConsentReason = "must include either a Consent screen or a pre-supplied consentInformation"

/// The configuration the structural rules read: the run's own screens and payloads, and the ML and
/// network defaults, because this overload consults neither and the run supplies both itself. The
/// default client is built and dropped once per entry, which is the cost of the only public shape.
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
  /// The sentence the card reports. Strings, not the exceptions, so nothing that renders a run has to
  /// import the SDK.
  var useSmileIDSampleReason: String {
    message.isEmpty ? String(describing: type(of: self)) : message
  }
}
