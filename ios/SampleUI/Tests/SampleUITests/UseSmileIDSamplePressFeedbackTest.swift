@testable import SampleUI
import XCTest

final class UseSmileIDSamplePressFeedbackTest: XCTestCase {
  func testAHeldCardShrinksTo97Percent() {
    XCTAssertEqual(useSmileIDSamplePressScale(pressed: true, enabled: true, reduceMotion: false), 0.97)
  }

  func testACardAtRestKeepsItsSize() {
    XCTAssertEqual(useSmileIDSamplePressScale(pressed: false, enabled: true, reduceMotion: false), 1)
  }

  func testADisabledCardDoesNotShrink() {
    XCTAssertEqual(useSmileIDSamplePressScale(pressed: true, enabled: false, reduceMotion: false), 1)
  }

  func testACardDoesNotShrinkUnderReducedMotion() {
    XCTAssertEqual(useSmileIDSamplePressScale(pressed: true, enabled: true, reduceMotion: true), 1)
  }

  @MainActor
  func testPickingSomethingNewTicksThenActs() {
    var events: [String] = []
    UseSmileIDSampleSelectionTick.pick(alreadySelected: false, tick: { events.append("tick") }) { events.append("act") }
    XCTAssertEqual(events, ["tick", "act"])
  }

  @MainActor
  func testPickingWhatIsAlreadySelectedOnlyActs() {
    var events: [String] = []
    UseSmileIDSampleSelectionTick.pick(alreadySelected: true, tick: { events.append("tick") }) { events.append("act") }
    XCTAssertEqual(events, ["act"])
  }
}
