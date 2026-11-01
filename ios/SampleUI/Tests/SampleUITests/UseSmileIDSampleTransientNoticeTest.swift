import SampleUI
import XCTest

/// A notice's identity, which its host keys the dismissal window on.
final class UseSmileIDSampleTransientNoticeTest: XCTestCase {
  func testTheSameWordsShownTwiceAreTwoNotices() {
    XCTAssertNotEqual(
      UseSmileIDSampleTransientNotice(message: "Job ID copied"),
      UseSmileIDSampleTransientNotice(message: "Job ID copied")
    )
  }

  func testANoticeIsStillItselfOnARedraw() {
    let notice = UseSmileIDSampleTransientNotice(message: "Job ID copied")
    XCTAssertEqual(notice, notice)
  }
}
