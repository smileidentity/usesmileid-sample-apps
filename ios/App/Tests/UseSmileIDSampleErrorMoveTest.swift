import SampleUI
@testable import UseSmileIDSample
import XCTest

/// Where each failure action takes the user, per the `does` lines of spec/error-handling.json.
final class UseSmileIDSampleErrorMoveTest: XCTestCase {
  func testARetryALaterRetryAndARecaptureRunTheVerificationAgain() {
    for action in [UseSmileIDSampleErrorAction.retry, .retryLater, .recapture] {
      XCTAssertEqual(useSmileIDSampleErrorMove(action, product: .biometricKyc), .runAgain(.biometricKyc), action.rawValue)
    }
  }

  func testFixingTheInputReturnsToTheIdForm() {
    XCTAssertEqual(useSmileIDSampleErrorMove(.fixInput, product: .biometricKyc), .editIdDetails(.biometricKyc))
  }

  func testStartingAgainTakesANewTokenFirst() {
    XCTAssertEqual(useSmileIDSampleErrorMove(.newSession, product: .biometricKyc), .newToken(.biometricKyc))
  }

  func testCloseLeavesTheRun() {
    XCTAssertEqual(useSmileIDSampleErrorMove(.exit, product: .biometricKyc), .leave)
  }

  func testARunWhoseProductWasNotKeptCanOnlyLeave() {
    for action in UseSmileIDSampleErrorAction.allCases {
      XCTAssertEqual(useSmileIDSampleErrorMove(action, product: nil), .leave, action.rawValue)
    }
  }
}
