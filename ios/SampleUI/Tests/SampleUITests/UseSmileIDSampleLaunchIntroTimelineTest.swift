@testable import SampleUI
import XCTest

final class UseSmileIDSampleLaunchIntroTimelineTest: XCTestCase {
  func testTheFirstFrameIsAnEmptyScreen() {
    let pose = LaunchIntroTimeline.pose(0)

    XCTAssertEqual(pose.markAlpha, 0)
    XCTAssertEqual(pose.wordmarkReveal, 0)
  }

  func testTheLogoStartsUnlockedAtItsOwnSize() {
    let pose = LaunchIntroTimeline.pose(LaunchIntroTimeline.appeared)

    XCTAssertEqual(pose.markAlpha, 1)
    XCTAssertEqual(pose.markScale, 1)
    XCTAssertEqual(pose.shackleLock, 0)
  }

  func testTheLockShutsWhileTheNameIsStillUnrolling() {
    let pose = LaunchIntroTimeline.pose(LaunchIntroTimeline.locked)

    XCTAssertEqual(pose.shackleLock, 1)
    XCTAssertEqual(pose.shackleLift, 0)
    XCTAssertTrue(pose.wordmarkReveal > 0 && pose.wordmarkReveal < 1, "the name is part-way out")
  }

  func testTheLastFrameIsTheLogoAtRestUnlockedAgain() {
    XCTAssertEqual(LaunchIntroTimeline.pose(1), LaunchIntroPose.rest)
  }

  func testTheShackleOnlyEverLiftsNeverSinksIntoTheBody() {
    let lifts = (0...1000).map { LaunchIntroTimeline.pose(Double($0) / 1000).shackleLift }

    XCTAssertTrue(lifts.allSatisfy { $0 >= 0 })
  }

  func testProgressOutsideTheTimelineIsClamped() {
    XCTAssertEqual(LaunchIntroTimeline.pose(-1), LaunchIntroTimeline.pose(0))
    XCTAssertEqual(LaunchIntroTimeline.pose(2), LaunchIntroTimeline.pose(1))
  }

  func testTheEasingCurvesMatchTheirCubicBeziers() {
    XCTAssertEqual(LaunchIntroEasing.fastOutSlowIn(0), 0)
    XCTAssertEqual(LaunchIntroEasing.fastOutSlowIn(1), 1)
    XCTAssertEqual(LaunchIntroEasing.fastOutSlowIn(0.5), 0.7756, accuracy: 0.001)
    XCTAssertEqual(LaunchIntroEasing.linearOutSlowIn(0.5), 0.8392, accuracy: 0.001)
  }

  func testEveryLogoPartParsesToItsDeclaredBounds() {
    let paths = UseSmileIDSampleLogo.Paths()

    assertBounds(paths.body.boundingRect, CGRect(x: 79.5, y: 7.86, width: 5.32, height: 4.98))
    assertBounds(paths.shackle.boundingRect, CGRect(x: 83.4, y: 3, width: 5.3, height: 4.86))
    assertBounds(
      paths.wordmark.boundingRect,
      UseSmileIDSampleLogo.wordmarkBounds,
      accuracy: 0.05
    )
  }

  private func assertBounds(_ actual: CGRect, _ expected: CGRect, accuracy: CGFloat = 0.01, line: UInt = #line) {
    XCTAssertEqual(actual.minX, expected.minX, accuracy: accuracy, line: line)
    XCTAssertEqual(actual.minY, expected.minY, accuracy: accuracy, line: line)
    XCTAssertEqual(actual.maxX, expected.maxX, accuracy: accuracy, line: line)
    XCTAssertEqual(actual.maxY, expected.maxY, accuracy: accuracy, line: line)
  }
}
