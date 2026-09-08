import Foundation
import SampleUI

/// Read once at flow entry; never re-read while the flow runs (R2).
struct FlowLaunchSnapshot: Equatable {
  let product: UseSmileIDSampleProduct
  let route: UseSmileIDSampleFlowRoute
  let userDetails: UseSmileIDSampleUserDetails
  let idDetails: UseSmileIDSampleIdDetails
  let scenario: UseSmileIDSampleScenario
  let theme: UseSmileIDSampleThemeScenario
  let sandbox: Bool
  /// The five fields, not the settings object: the snapshot is read once at entry (R2).
  let allowAgentMode: Bool
  let enableEnhancedLiveness: Bool
  let consentStep: Bool
  let instructionsStep: Bool
  let previewStep: Bool
  let userId: String
  let partnerId: String
  let partnerName: String
  /// Live at entry only: a session that has run out is the gate's business, never the builder's.
  let session: UseSmileIDSampleTokenSession?
  /// Run out — the one thing that routes back to the scanner. Usually true with no ``session``.
  let sessionExpired: Bool

  init(
    product: UseSmileIDSampleProduct,
    route: UseSmileIDSampleFlowRoute,
    userDetails: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    idDetails: UseSmileIDSampleIdDetails = UseSmileIDSampleIdDetails(),
    scenario: UseSmileIDSampleScenario = .normal,
    theme: UseSmileIDSampleThemeScenario = .brandDefault,
    sandbox: Bool = true,
    allowAgentMode: Bool = false,
    enableEnhancedLiveness: Bool = true,
    consentStep: Bool = true,
    instructionsStep: Bool = true,
    previewStep: Bool = true,
    userId: String = "",
    partnerId: String = "",
    partnerName: String = "",
    session: UseSmileIDSampleTokenSession? = nil,
    sessionExpired: Bool = false
  ) {
    self.product = product
    self.route = route
    self.userDetails = userDetails
    self.idDetails = idDetails
    self.scenario = scenario
    self.theme = theme
    self.sandbox = sandbox
    self.allowAgentMode = allowAgentMode
    self.enableEnhancedLiveness = enableEnhancedLiveness
    self.consentStep = consentStep
    self.instructionsStep = instructionsStep
    self.previewStep = previewStep
    self.userId = userId
    self.partnerId = partnerId
    self.partnerName = partnerName
    self.session = session
    self.sessionExpired = sessionExpired
  }

  var environment: UseSmileIDSampleEnvironment {
    sandbox ? .sandbox : .production
  }
}

@MainActor
func buildSnapshot(
  productId: String,
  route: UseSmileIDSampleFlowRoute,
  app: UseSmileIDSampleAppState,
  userId: String
) -> FlowLaunchSnapshot? {
  guard let product = UseSmileIDSampleProduct(rawValue: productId) else { return nil }
  // The clock is read here rather than through the app state's ticking value: the snapshot is taken
  // once at entry (R2), and subscribing the flow host to a once-a-second tick would re-render it —
  // which the SDK answers by re-running `build()` and tearing the run down.
  let entry = Date()
  let session = app.session
  return FlowLaunchSnapshot(
    product: product,
    route: route,
    userDetails: app.userDetails,
    idDetails: app.idDetails,
    scenario: app.flowResult.scenario,
    theme: app.flowResult.theme,
    sandbox: app.useSandbox,
    allowAgentMode: app.settings.agentMode,
    enableEnhancedLiveness: app.settings.enhancedSmartSelfie,
    consentStep: app.settings.consentStep,
    instructionsStep: app.settings.instructionsStep,
    previewStep: app.settings.previewStep,
    userId: userId,
    partnerId: app.profiles.active.id,
    partnerName: app.profiles.active.organisation,
    session: session.flatMap { $0.hasExpired(at: entry) ? nil : $0 },
    sessionExpired: app.endedSession != nil || session?.hasExpired(at: entry) == true
  )
}
