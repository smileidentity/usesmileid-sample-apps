@testable import UseSmileIDSample
import XCTest

final class UseSmileIDSampleLaunchIntroGateTest: XCTestCase {
  func testAColdStartFromTheAppIconPlaysTheIntro() {
    XCTAssertTrue(UseSmileIDSampleLaunchIntroGate.plays(arguments: [:], restored: false, reduceMotion: false))
  }

  func testARestoredSceneGoesStraightToTheApp() {
    XCTAssertFalse(UseSmileIDSampleLaunchIntroGate.plays(arguments: [:], restored: true, reduceMotion: false))
  }

  func testReduceMotionSkipsIt() {
    XCTAssertFalse(UseSmileIDSampleLaunchIntroGate.plays(arguments: [:], restored: false, reduceMotion: true))
  }

  func testAnAutomationLaunchArgumentSkipsIt() {
    let arguments: [String: Any] = [UseSmileIDSampleLaunchArguments.probesName: "true"]

    XCTAssertFalse(UseSmileIDSampleLaunchIntroGate.plays(arguments: arguments, restored: false, reduceMotion: false))
  }

  func testTheArgumentAnSdkRepositoryReservesSkipsIt() {
    XCTAssertFalse(
      UseSmileIDSampleLaunchIntroGate.plays(arguments: ["e2eScenario": "x"], restored: false, reduceMotion: false)
    )
  }

  func testASeededSettingSkipsIt() {
    XCTAssertFalse(
      UseSmileIDSampleLaunchIntroGate.plays(arguments: ["appearance": "light"], restored: false, reduceMotion: false)
    )
  }

  func testAnArgumentTheSystemAddsStillPlaysIt() {
    let arguments: [String: Any] = ["NSDocumentRevisionsDebugMode": "YES"]

    XCTAssertTrue(UseSmileIDSampleLaunchIntroGate.plays(arguments: arguments, restored: false, reduceMotion: false))
  }
}
