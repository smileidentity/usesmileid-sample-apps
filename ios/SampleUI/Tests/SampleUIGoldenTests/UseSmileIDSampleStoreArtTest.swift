@testable import SampleUI
import SnapshotTesting
import SwiftUI
import XCTest

/// The App Store panels: frames only, written to ios/store/frames and rendered by ios/store/render-store-art.sh.
@MainActor
final class UseSmileIDSampleStoreArtTest: XCTestCase {
  /// 440 × 956 pt is the ios-phone preset's 1320 × 2868 at the recorder's 3× scale.
  private static let size = CGSize(width: 440, height: 956)

  /// The frame's corner radius eats the top 153 px of the source; 62 pt clears it and is also the
  /// phone's real status-bar height, so the band reads as one — docs/plan/app-store-release-ios.md §2.4.
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
      ProductsScreen(state: .init(initials: "KB"), onProduct: { _ in }, onProfile: {}, onScan: {})
    }
  }

  /// The same screen mid-session: the countdown is the state, and it is fixed text rather than a clock.
  func testTokenSession() {
    panel("token_session") {
      ProductsScreen(
        state: .init(initials: "KB", sessionId: "a41f", sessionRemaining: "07:12"),
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
          today: useSmileIDSampleStartOfDay(Self.now, calendar: Self.utc),
          calendar: Self.utc
        ),
        onFilterChange: { _ in },
        onSelectModeChange: { _ in },
        onSelectionChange: { _, _ in },
        onJobTap: { _ in },
        onRemove: { _ in }
      )
    }
  }

  /// Probes off, because a plain release install hides the result card and store art must not show
  /// a state the App Store reviewer's own build cannot reach.
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
          organisation: "Kobo Bank",
          initials: "KB",
          versionLabel: "UseSmileID Sample 1.0 · SDK 12.1.1",
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

    // verifySnapshot rather than assertSnapshot: only it takes snapshotDirectory, which is what
    // keeps the frames out of __Snapshots__. testName is the panel, so the file is <panel>.frame.png.
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

  /// 2026-07-16T11:50:12Z, the instant the design's rows are dated from; the store art must not move with the clock.
  private static let now = Date(timeIntervalSince1970: 1784202612)

  private static let jobs = UseSmileIDSampleJobStore.fixtures(now: now)

  private static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }
}

/// Reads the themed background, which the panel cannot do before the theme is in the environment.
private struct StoreArtBackground: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    colors.background
  }
}
