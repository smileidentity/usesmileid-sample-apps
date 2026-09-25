import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleFlowPreflightTest: XCTestCase {
  func testAnEndedSessionAsksForATokenBeforeAnythingElse() {
    let blank = snapshot(.biometricKyc, sessionExpired: true)
    XCTAssertEqual(useSmileIDSamplePreflight(blank), .needsSession)
  }

  func testCompleteDetailsPassTheGate() {
    XCTAssertEqual(useSmileIDSamplePreflight(snapshot(.smartSelfieEnrollment, userDetails: complete)), .ready)
  }

  func testEmptyDetailsAreSentToTheForm() {
    guard case .needsDetails(let issues) = useSmileIDSamplePreflight(snapshot(.smartSelfieEnrollment)) else {
      return XCTFail("an empty payload passed the gate")
    }
    XCTAssertFalse(issues.isEmpty, "the redirect carries no reason")
  }

  func testAKycRunWithNoIdNumberIsSentToTheForm() {
    let missing = snapshot(.biometricKyc, userDetails: complete)
    guard case .needsDetails = useSmileIDSamplePreflight(missing) else {
      return XCTFail("a blank ID payload passed the gate")
    }
    let complete = snapshot(
      .biometricKyc,
      userDetails: complete,
      idDetails: UseSmileIDSampleIdDetails(country: .kenya, idType: .nationalId, idNumber: "1234567")
    )
    XCTAssertEqual(useSmileIDSamplePreflight(complete), .ready)
  }

  func testATokenThatBindsTheDetailsPassesAnEmptyForm() {
    let bound = snapshot(
      .smartSelfieEnrollment,
      session: session(bindings: UseSmileIDSampleTokenBindings(givenNames: true, lastName: true, email: true))
    )
    XCTAssertEqual(useSmileIDSamplePreflight(bound), .ready)
  }

  func testAPartialBindingStillGoesToTheForm() {
    let partial = snapshot(
      .smartSelfieEnrollment,
      session: session(bindings: UseSmileIDSampleTokenBindings(givenNames: true))
    )
    guard case .needsDetails = useSmileIDSamplePreflight(partial) else {
      return XCTFail("a partial binding was treated as a whole one")
    }
  }

  func testARefreshScenarioDoesNotReadTheBindings() {
    let expired = snapshot(
      .smartSelfieEnrollment,
      scenario: .badRefresh,
      session: session(bindings: UseSmileIDSampleTokenBindings(givenNames: true, lastName: true, email: true))
    )
    guard case .needsDetails = useSmileIDSamplePreflight(expired) else {
      return XCTFail("a scenario that starts expired read the token's bindings")
    }
  }

  /// By design no host's gate checks consent; pinned so no platform diverges alone.
  func testAJourneyWithNoConsentAtAllStillReachesTheSdk() {
    let neither = snapshot(.smartSelfieEnrollment, userDetails: complete, consentStep: false)
    XCTAssertEqual(useSmileIDSamplePreflight(neither), .ready)
  }

  func testAgentModeWithEnhancedLivenessIsBlockedRatherThanRedirected() {
    let both = snapshot(.smartSelfieEnrollment, userDetails: complete, agentMode: true, enhancedLiveness: true)
    guard case .misconfigured(let issues) = useSmileIDSamplePreflight(both) else {
      return XCTFail("the pair the SDK refuses passed the gate")
    }
    XCTAssertFalse(issues.isEmpty, "the block carries no reason for the card to report")
    // Falsified: either one alone is a valid run.
    XCTAssertEqual(
      useSmileIDSamplePreflight(snapshot(.smartSelfieEnrollment, userDetails: complete, agentMode: true)),
      .ready
    )
  }

  func testEveryProductWithItsPayloadFilledPassesTheGate() {
    for product in UseSmileIDSampleProduct.allCases {
      let filled = snapshot(
        product,
        userDetails: complete,
        idDetails: UseSmileIDSampleIdDetails(country: .kenya, idType: .nationalId, idNumber: "1234567")
      )
      XCTAssertEqual(useSmileIDSamplePreflight(filled), .ready, product.id)
    }
  }

  // MARK: - Fixtures

  private let complete = UseSmileIDSampleUserDetails(
    firstName: "Kwame",
    lastName: "Asante",
    email: "kwame@uptech.example"
  )

  private func session(bindings: UseSmileIDSampleTokenBindings) -> UseSmileIDSampleTokenSession {
    UseSmileIDSampleTokenSession(
      id: "handle",
      token: "token",
      issuedAt: Date(timeIntervalSince1970: 1000000),
      expiresAt: Date(timeIntervalSince1970: 1003600),
      bindings: bindings,
      partnerId: "0000",
      environment: .sandbox
    )
  }

  private func snapshot(
    _ product: UseSmileIDSampleProduct,
    scenario: UseSmileIDSampleScenario = .normal,
    userDetails: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    idDetails: UseSmileIDSampleIdDetails = UseSmileIDSampleIdDetails(),
    agentMode: Bool = false,
    enhancedLiveness: Bool = false,
    consentStep: Bool = true,
    session: UseSmileIDSampleTokenSession? = nil,
    sessionExpired: Bool = false
  ) -> FlowLaunchSnapshot {
    FlowLaunchSnapshot(
      product: product,
      route: .fullscreen,
      userDetails: userDetails,
      idDetails: idDetails,
      scenario: scenario,
      allowAgentMode: agentMode,
      enableEnhancedLiveness: enhancedLiveness,
      consentStep: consentStep,
      partnerId: "0000",
      partnerName: "UpTech Finance",
      session: session,
      sessionExpired: sessionExpired
    )
  }
}
