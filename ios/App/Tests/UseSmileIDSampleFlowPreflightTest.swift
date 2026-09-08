import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleFlowPreflightTest: XCTestCase {
  /// Ahead of every payload check, because no form fixes a session that has run out.
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

  /// The ID payload is checked too, so a KYC run with no ID number never reaches the SDK.
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

  /// A token that binds both names and a contact field answers the form, so an empty form still
  /// passes: the issues the SDK reports are the ones the bindings cover.
  func testATokenThatBindsTheDetailsPassesAnEmptyForm() {
    let bound = snapshot(
      .smartSelfieEnrollment,
      session: session(bindings: UseSmileIDSampleTokenBindings(givenNames: true, lastName: true, email: true))
    )
    XCTAssertEqual(useSmileIDSamplePreflight(bound), .ready)
  }

  /// Falsifies the subtraction: a token binding only one name leaves the rest outstanding.
  func testAPartialBindingStillGoesToTheForm() {
    let partial = snapshot(
      .smartSelfieEnrollment,
      session: session(bindings: UseSmileIDSampleTokenBindings(givenNames: true))
    )
    guard case .needsDetails = useSmileIDSamplePreflight(partial) else {
      return XCTFail("a partial binding was treated as a whole one")
    }
  }

  /// The gate reads the bindings through the same live-session rule the forms do, so a refresh
  /// scenario cannot skip a form and then be redirected back to it.
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

  /// The per-job-type rule the one-argument validator does not run: every job type needs consent,
  /// from a screen or from the token. Turning the Consent screen switch off with no consent binding
  /// leaves neither, and the SDK refuses the flow — the whole point of the gate is that it says so
  /// before the SDK mounts, rather than delivering it as a Failure a test cannot tell from a real one.
  func testAJourneyWithNoConsentAtAllIsBlockedRatherThanRedirected() {
    let neither = snapshot(.smartSelfieEnrollment, userDetails: complete, consentStep: false)
    guard case .misconfigured(let issues) = useSmileIDSamplePreflight(neither) else {
      return XCTFail("a flow with no source of consent passed the gate")
    }
    XCTAssertFalse(issues.isEmpty, "the block carries no reason for the card to report")

    // Falsified both ways: the switch back on, and the switch off against a token that binds consent.
    XCTAssertEqual(useSmileIDSamplePreflight(snapshot(.smartSelfieEnrollment, userDetails: complete)), .ready)
    let bound = snapshot(
      .smartSelfieEnrollment,
      userDetails: complete,
      consentStep: false,
      session: session(bindings: UseSmileIDSampleTokenBindings(consent: UseSmileIDSampleTokenConsent(granted: true)))
    )
    XCTAssertEqual(useSmileIDSamplePreflight(bound), .ready)
  }

  /// The pair the SDK refuses: agent mode captures on the rear lens and the head-turn challenge is
  /// only validated for front-camera framing. Settings holds a mutex so no reader can set both, and
  /// this is the gate that would still stop it — no form fixes it, and it must never reach the SDK.
  func testAgentModeWithEnhancedLivenessIsBlockedRatherThanRedirected() {
    let both = snapshot(.smartSelfieEnrollment, userDetails: complete, agentMode: true, enhancedLiveness: true)
    guard case .misconfigured(let issues) = useSmileIDSamplePreflight(both) else {
      return XCTFail("the pair the SDK refuses passed the gate")
    }
    XCTAssertFalse(issues.isEmpty, "the block carries no reason for the card to report")
    // Falsified by the mutex's own state: either one alone is a valid run.
    XCTAssertEqual(
      useSmileIDSamplePreflight(snapshot(.smartSelfieEnrollment, userDetails: complete, agentMode: true)),
      .ready
    )
  }

  /// Every product's happy path passes the gate, which is what stops a rule written for one journey
  /// from blocking another.
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
