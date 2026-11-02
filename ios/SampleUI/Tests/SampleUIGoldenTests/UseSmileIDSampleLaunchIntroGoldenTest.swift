@testable import SampleUI
import SwiftUI
import XCTest

/// The intro stopped on its two named frames; it draws on the dark scheme whatever the device's, so both baselines match.
final class UseSmileIDSampleLaunchIntroGoldenTest: UseSmileIDSampleGoldenTest {
  func testLocked() {
    goldens("launch_intro_locked") { frame(LaunchIntroTimeline.locked) }
  }

  func testLogo() {
    goldens("launch_intro_logo") { frame(1) }
  }

  /// A canvas has no height of its own, so it takes a phone-shaped one to be drawn as it is on screen.
  private func frame(_ progress: Double) -> some View {
    LaunchIntroFrame(progress: progress).frame(height: Self.frameHeight)
  }

  private static let frameHeight: CGFloat = 760
}
