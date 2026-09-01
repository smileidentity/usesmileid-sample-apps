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

  /// The four states `spec/screens.json` lists, which differ by badge, message and HTTP colour.
  func testVerificationDetailsClear() {
    goldens("verification_details_clear") { details(Self.fixture(.clear, index: 0)) }
  }

  func testVerificationDetailsAttention() {
    goldens("verification_details_attention") { details(Self.fixture(.attention, index: 3)) }
  }

  func testVerificationDetailsBlocked() {
    goldens("verification_details_blocked") { details(Self.fixture(.blocked, index: 4)) }
  }

  /// 202 Accepted, which is the one status a refresh can still change.
  func testVerificationDetailsProcessing() {
    goldens("verification_details_processing") { details(Self.fixture(.processing, index: 1)) }
  }

  /// A deep link can name a job this build never had; the id asked for is the whole diagnostic.
  func testVerificationDetailsUnknownJob() {
    goldens("verification_details_unknown") {
      VerificationDetailsScreen(
        state: .init(jobId: "job_missing"),
        onBack: {},
        onDelete: {},
        onCopy: { _, _ in }
      )
      .frame(height: 560)
    }
  }

  /// A taller viewport than the state goldens: this baseline exists to be read for clipping, and
  /// at the largest content size the rows sit below 560pt.
  func testVerificationDetailsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      details(Self.fixture(.processing, index: 1), height: 1800)
    }
  }

  private func details(_ job: UseSmileIDSampleJob, height: CGFloat = 560) -> some View {
    VerificationDetailsScreen(
      state: .init(jobId: job.id, job: job),
      onBack: {},
      onDelete: {},
      onCopy: { _, _ in }
    )
    .frame(height: height)
  }

  /// The store's own rows, until the store lands: same ids, same offsets, same product strings the
  /// four apps share.
  private static func fixture(_ status: UseSmileIDSampleStatus, index: Int) -> UseSmileIDSampleJob {
    let products = UseSmileIDSampleProduct.allCases
    return UseSmileIDSampleJob(
      id: String(format: "job_%02dky31za%02d", index, index * 7 % 100),
      userId: String(format: "user_%02dky31za%02d", index, index * 3 % 100),
      product: products[index % products.count],
      status: status,
      createdAt: Self.fixedNow.addingTimeInterval(TimeInterval(-index * 5 * 60 * 60)),
      message: Self.message(status),
      httpStatus: status == .processing ? 202 : 200
    )
  }

  private static func message(_ status: UseSmileIDSampleStatus) -> String {
    switch status {
    case .clear: "Approved"
    case .attention: "Provisional \u{2014} needs review"
    case .blocked: "Rejected"
    case .processing: "Submitted, awaiting result"
    }
  }

  /// 2026-07-16T11:50:12Z, the instant the design's rows are dated from. Fixed, so the row a golden
  /// records is the one it compares against tomorrow.
  private static let fixedNow = Date(timeIntervalSince1970: 1784202612)

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
