@testable import SampleUI
import SnapshotTesting
import SwiftUI
import XCTest

/// The App Store panels: frames only, written to ios/store/frames and rendered by ios/store/render-store-art.sh.
/// The demo organisation, initials and session are Android's `StoreArtTest` values, so the two listings show one app.
@MainActor
final class UseSmileIDSampleStoreArtTest: XCTestCase {
  /// 440 × 956 pt is the ios-phone preset's 1320 × 2868 at the recorder's 3× scale.
  private static let size = CGSize(width: 440, height: 956)

  /// Clears the frame's 153 px corner radius and matches the phone's status bar — see docs/plan/app-store-release-ios.md §2.4.
  private static let statusBarInset: CGFloat = 62

  /// Its own directory, so a store-art change can never quietly repaint a golden.
  private static var frames: String {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // the file
      .deletingLastPathComponent() // SampleUIGoldenTests
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // SampleUI
      .appendingPathComponent("store/frames")
      .path
  }

  func testProducts() {
    panel("products") {
      ProductsScreen(state: .init(initials: "KA"), onProduct: { _ in }, onProfile: {}, onScan: {})
    }
  }

  /// The same screen mid-session: the countdown is the state, and it is fixed text rather than a clock.
  func testTokenSession() {
    panel("token_session") {
      ProductsScreen(
        state: .init(initials: "KA", sessionId: "9f3a2c71", sessionRemaining: "7:59:12"),
        onProduct: { _ in },
        onProfile: {},
        onScan: {}
      )
    }
  }

  func testVerifications() {
    panel("verifications") {
      VerificationsScreen(
        state: .init(
          jobs: Self.jobs,
          counts: Dictionary(
            uniqueKeysWithValues: UseSmileIDSampleJobFilter.allCases
              .map { ($0, Self.jobs.filter($0.matches).count) }
          ),
          filter: .all,
          selectMode: false,
          selected: [],
          today: useSmileIDSampleStartOfDay(UseSmileIDSampleFixedClock.now, calendar: UseSmileIDSampleFixedClock.utc),
          calendar: UseSmileIDSampleFixedClock.utc
        ),
        onFilterChange: { _ in },
        onSelectModeChange: { _ in },
        onSelectionChange: { _, _ in },
        onJobTap: { _ in },
        onRemove: { _ in }
      )
    }
  }

  /// Probes off: a plain release install hides the result card, so store art must not show it.
  func testVerificationDetails() {
    let job = Self.jobs[0]
    panel("verification_details") {
      VerificationDetailsScreen(
        state: .init(
          jobId: job.id,
          job: job,
          result: UseSmileIDSampleResultFixtures.succeeded,
          showProbes: false
        ),
        resultExpanded: .constant(true),
        onBack: {},
        onDelete: {},
        onCopy: { _, _ in }
      )
    }
  }

  func testSettings() {
    panel("settings") {
      SettingsScreen(
        state: .init(
          settings: UseSmileIDSampleSettings(),
          organisation: "UpTech Finance",
          initials: "KA",
          versionLabel: "Smile ID 1.0 · SDK 12.1.1",
          consentBoundByToken: false,
          avatarColor: useSmileIDSampleAvatarColor(profileIndex: 0)
        ),
        onSettingChange: { _, _ in },
        onProfile: {},
        onNavRow: { _ in },
        onOpenScenarioDrawer: nil,
        onSignOut: {}
      )
    }
  }

  /// Light only, and one variant for the whole set: six panels at different heights read as inconsistency.
  private func panel(
    _ name: String,
    file: StaticString = #filePath,
    line: UInt = #line,
    @ViewBuilder content: () -> some View
  ) {
    let view = VStack(spacing: 0) {
      Color.clear.frame(height: Self.statusBarInset)
      content()
    }
    .frame(width: Self.size.width, height: Self.size.height)
    .background(StoreArtBackground())
    .useSmileIDSampleTheme()

    // verifySnapshot, not assertSnapshot: only it takes snapshotDirectory, which keeps the frames
    // out of __Snapshots__.
    let failure = verifySnapshot(
      of: view,
      as: .image(
        layout: .fixed(width: Self.size.width, height: Self.size.height),
        traits: .init(userInterfaceStyle: .light)
      ),
      named: "frame",
      snapshotDirectory: Self.frames,
      file: file,
      testName: name,
      line: line
    )
    if let failure {
      XCTFail(failure, file: file, line: line)
    }
  }

  private static let jobs = UseSmileIDSampleJobStore.fixtures(now: UseSmileIDSampleFixedClock.now)
}

/// Reads the themed background, which the panel cannot do before the theme is in the environment.
private struct StoreArtBackground: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    colors.background
  }
}
