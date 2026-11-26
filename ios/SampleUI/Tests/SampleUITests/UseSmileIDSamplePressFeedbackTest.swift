@testable import SampleUI
import SwiftUI
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

  func testASmallChangeEasesOverTheFastDuration() {
    XCTAssertEqual(useSmileIDSampleFastAnimation(reduceMotion: false), .easeOut(duration: SmileMotion.durationFast))
  }

  func testASmallChangeSnapsUnderReducedMotion() {
    XCTAssertNil(useSmileIDSampleFastAnimation(reduceMotion: true))
  }

  func testABarRisesOverTheToastEntrance() {
    XCTAssertEqual(useSmileIDSampleRiseAnimation(reduceMotion: false), .timingCurve(0.4, 0, 0.2, 1, duration: 0.22))
  }

  func testABarIsInPlaceAtOnceUnderReducedMotion() {
    XCTAssertNil(useSmileIDSampleRiseAnimation(reduceMotion: true))
  }
}
