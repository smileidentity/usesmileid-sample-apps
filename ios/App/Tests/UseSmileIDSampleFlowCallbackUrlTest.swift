import SampleUI
@testable import UseSmileIDSample
import XCTest

final class UseSmileIDSampleFlowCallbackUrlTest: XCTestCase {
  func testWithoutASessionTheProfilesWebhookIsWhatTheJobCarries() {
    XCTAssertEqual(snapshot(session: nil).resolvedCallbackUrl, Self.profileUrl)
  }

  func testALiveSessionDropsItWhetherOrNotTheTokenBindsOneOfItsOwn() {
    XCTAssertEqual(snapshot(session: session()).resolvedCallbackUrl, "")
    XCTAssertEqual(snapshot(session: session(callbackUrl: "https://token.example/hook")).resolvedCallbackUrl, "")
  }

  func testTheRowSaysWhichOfTheTwoApplies() {
    XCTAssertEqual(session().callbackOverrideCaption, "The scanned token's partner default applies")
    XCTAssertEqual(
      session(callbackUrl: "https://token.example/hook").callbackOverrideCaption,
      "Set by the scanned token"
    )
  }

  private func session(callbackUrl: String? = nil) -> UseSmileIDSampleTokenSession {
    UseSmileIDSampleTokenSession(
      id: "handle",
      token: "token",
      issuedAt: Date(timeIntervalSince1970: 1000000),
      expiresAt: Date(timeIntervalSince1970: 1003600),
      bindings: UseSmileIDSampleTokenBindings(callbackUrl: callbackUrl),
      partnerId: "0000",
      environment: .sandbox
    )
  }

  private func snapshot(session: UseSmileIDSampleTokenSession?) -> FlowLaunchSnapshot {
    FlowLaunchSnapshot(
      product: .smartSelfieEnrollment,
      route: .fullscreen,
      partnerId: "0000",
      partnerName: "UpTech Finance",
      callbackUrl: Self.profileUrl,
      session: session
    )
  }

  private static let profileUrl = "https://profile.example/hook"
}
