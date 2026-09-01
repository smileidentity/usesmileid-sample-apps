@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleScreenGoldenTest: UseSmileIDSampleGoldenTest {
  func testProductsNoSession() {
    goldens("products_no_session") { products(.init(initials: "KB")) }
  }

  func testProductsActiveSession() {
    goldens("products_active_session") {
      products(.init(initials: "KB", sessionId: "a41f", sessionRemaining: "07:12"))
    }
  }

  func testProductsSessionEnded() {
    goldens("products_session_ended") { products(.init(initials: "KB", sessionEnded: true)) }
  }

  /// Fixed by the harness, not by the design: a screen scrolls, so its frame is pinned here and its
  /// content grows inside it rather than making the frame taller.
  func testProductsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      products(.init(initials: "KB", sessionId: "a41f", sessionRemaining: "07:12"))
    }
  }

  func testSettings() {
    goldens("settings") { settings(UseSmileIDSampleSettings()) }
  }

  /// Agent mode on: the capture pair is mutually exclusive, so both supporting lines change.
  func testSettingsAgentMode() {
    goldens("settings_agent_mode") {
      settings(UseSmileIDSampleSettings(enhancedSmartSelfie: false, agentMode: true), consentBound: true)
    }
  }

  func testSettingsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { settings(UseSmileIDSampleSettings()) }
  }

  private func products(_ state: UseSmileIDSampleProductsState) -> some View {
    ProductsScreen(state: state, onProduct: { _ in }, onProfile: {}, onScan: {})
      .frame(height: 900)
  }

  private func settings(_ values: UseSmileIDSampleSettings, consentBound: Bool = false) -> some View {
    SettingsScreen(
      state: .init(
        settings: values,
        organisation: "Kobo Bank",
        initials: "KB",
        versionLabel: "UseSmileID Sample 1.0 · SDK 12.0.2",
        consentBoundByToken: consentBound
      ),
      onSettingChange: { _, _ in },
      onProfile: {},
      onNavRow: { _ in },
      onOpenScenarioDrawer: {},
      onSignOut: {}
    )
    .frame(height: 1400)
  }
}
