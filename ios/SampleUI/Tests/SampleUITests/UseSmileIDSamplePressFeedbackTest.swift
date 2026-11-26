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

  func testAHeldCardDimsInsteadUnderReducedMotion() {
    XCTAssertEqual(useSmileIDSamplePressOpacity(pressed: true, enabled: true, reduceMotion: true), 0.7)
  }

  func testAHeldCardDoesNotDimWhenItCanShrink() {
    XCTAssertEqual(useSmileIDSamplePressOpacity(pressed: true, enabled: true, reduceMotion: false), 1)
  }

  func testACardAtRestDoesNotDim() {
    XCTAssertEqual(useSmileIDSamplePressOpacity(pressed: false, enabled: true, reduceMotion: true), 1)
  }
}
