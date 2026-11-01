import Foundation
import SampleUI
import XCTest

/// A notice's identity, which its host keys the dismissal window on.
final class UseSmileIDSampleTransientNoticeTest: XCTestCase {
  func testTheSameWordsBuiltOnEachRedrawStayOneNotice() {
    XCTAssertEqual(
      UseSmileIDSampleTransientNotice(message: "Profile created", actionLabel: "Make active"),
      UseSmileIDSampleTransientNotice(message: "Profile created", actionLabel: "Make active")
    )
  }

  func testTwoShowingsOfTheSameWordsAreTwoNotices() {
    XCTAssertNotEqual(
      UseSmileIDSampleTransientNotice(message: "Job ID copied", showing: UUID()),
      UseSmileIDSampleTransientNotice(message: "Job ID copied", showing: UUID())
    )
  }
}
