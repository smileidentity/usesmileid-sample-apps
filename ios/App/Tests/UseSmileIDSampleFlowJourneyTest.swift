import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleFlowJourneyTest: XCTestCase {
  func testTheDefaultJourneyIsConsentInstructionsSelfiePreviewProcessing() {
    XCTAssertEqual(
      useSmileIDSampleJourneySteps(snapshot(.smartSelfieEnrollment)),
      [.consent, .instructions, .selfieCapture, .preview, .processing]
    )
  }

  func testEachStepSwitchTakesItsScreenOut() {
    let snapshot = snapshot(.smartSelfieEnrollment, consentStep: false, instructionsStep: false, previewStep: false)
    XCTAssertEqual(useSmileIDSampleJourneySteps(snapshot), [.selfieCapture, .processing])
  }

  func testEnhancedKycIsConsentAndProcessingOnly() {
    XCTAssertEqual(useSmileIDSampleJourneySteps(snapshot(.enhancedKyc)), [.consent, .processing])
    XCTAssertEqual(
      useSmileIDSampleJourneySteps(snapshot(.enhancedKyc, instructionsStep: false, previewStep: false)),
      [.consent, .processing]
    )
  }

  func testTheDocumentProductsCaptureInOppositeOrders() {
    XCTAssertEqual(
      useSmileIDSampleJourneySteps(snapshot(.documentVerification)),
      [.consent, .instructions, .documentCapture, .preview, .selfieCapture, .preview, .processing]
    )
    XCTAssertEqual(
      useSmileIDSampleJourneySteps(snapshot(.enhancedDocumentVerification)),
      [.consent, .instructions, .selfieCapture, .preview, .documentCapture, .preview, .processing]
    )
  }

  func testAConsentBindingDropsTheConsentScreenEvenWithTheSwitchOn() {
    let bound = snapshot(.smartSelfieEnrollment, session: session(bindings: consentBindings))
    XCTAssertEqual(useSmileIDSampleJourneySteps(bound), [.instructions, .selfieCapture, .preview, .processing])
  }

  func testARefreshScenarioIgnoresTheSessionsBindings() {
    let expired = snapshot(
      .smartSelfieEnrollment,
      scenario: .expiredToken,
      session: session(bindings: consentBindings)
    )
    XCTAssertEqual(
      useSmileIDSampleJourneySteps(expired),
      [.consent, .instructions, .selfieCapture, .preview, .processing]
    )
  }

  func testTheScreensHandedToTheSdkMirrorTheSteps() {
    let snapshot = snapshot(.smartSelfieEnrollment)
    let steps = useSmileIDSampleFlowSteps(snapshot)
    XCTAssertEqual(steps.count, useSmileIDSampleJourneySteps(snapshot).count)
    guard case .consent(let consent) = steps.first else {
      return XCTFail("the journey does not start at consent")
    }
    XCTAssertEqual(consent.partnerName, "UpTech Finance")
    XCTAssertEqual(consent.partnerPrivacyPolicyUrl.absoluteString, "https://smile.id/privacy-policy")
  }

  func testTheSelfieCaptureCarriesTheSettingsUnswapped() {
    let steps = useSmileIDSampleFlowSteps(snapshot(.smartSelfieEnrollment, agentMode: true, enhancedLiveness: false))
    let selfie = steps.compactMap { step -> SelfieCaptureConfig? in
      guard case .capture(let capture) = step else { return nil }
      return capture.selfie
    }
    XCTAssertEqual(selfie.count, 1)
    XCTAssertEqual(selfie.first?.allowAgentMode, true)
    XCTAssertEqual(selfie.first?.enableEnhancedLiveness, false)
  }

  // MARK: - Fixtures

  private var consentBindings: UseSmileIDSampleTokenBindings {
    UseSmileIDSampleTokenBindings(consent: UseSmileIDSampleTokenConsent(granted: true))
  }

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
    consentStep: Bool = true,
    instructionsStep: Bool = true,
    previewStep: Bool = true,
    agentMode: Bool = false,
    enhancedLiveness: Bool = true,
    session: UseSmileIDSampleTokenSession? = nil
  ) -> FlowLaunchSnapshot {
    FlowLaunchSnapshot(
      product: product,
      route: .fullscreen,
      scenario: scenario,
      allowAgentMode: agentMode,
      enableEnhancedLiveness: enhancedLiveness,
      consentStep: consentStep,
      instructionsStep: instructionsStep,
      previewStep: previewStep,
      partnerId: "0000",
      partnerName: "UpTech Finance",
      session: session
    )
  }
}
