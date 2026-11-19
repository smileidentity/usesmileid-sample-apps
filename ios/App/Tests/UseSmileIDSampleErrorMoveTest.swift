import SampleUI
@testable import UseSmileIDSample
import XCTest

/// Where each failure action takes the user, per the `does` lines of spec/error-handling.json, under the gate a product tap passes.
final class UseSmileIDSampleErrorMoveTest: XCTestCase {
  private let reruns: [UseSmileIDSampleErrorAction] = [.retry, .retryLater, .recapture]

  func testARetryALaterRetryAndARecaptureRunTheVerificationAgainOnTheRunsOwnPartner() {
    for action in reruns {
      XCTAssertEqual(move(action, livePartnerId: "partner_1", runPartnerId: "partner_1"), .runAgain(.biometricKyc), action.rawValue)
    }
  }

  func testARerunOnAnotherOrAnUnknownPartnerStartsFromTheFirstStep() {
    for action in reruns {
      XCTAssertEqual(move(action, livePartnerId: "partner_2", runPartnerId: "partner_1"), .runFromStart(.biometricKyc), action.rawValue)
      XCTAssertEqual(move(action, livePartnerId: "partner_2", runPartnerId: nil), .runFromStart(.biometricKyc), action.rawValue)
    }
  }

  func testARerunWithNoLiveSessionScansFirstAndResumesInTheFlow() {
    for action in reruns {
      XCTAssertEqual(move(action, sessionLive: false), .newToken(.biometricKyc, resumeAt: .flow), action.rawValue)
    }
  }

  func testFixingTheInputReturnsToTheIdFormOrScansFirstWithNoLiveSession() {
    XCTAssertEqual(move(.fixInput), .editIdDetails(.biometricKyc))
    XCTAssertEqual(move(.fixInput, sessionLive: false), .newToken(.biometricKyc, resumeAt: .firstStep))
  }

  func testStartingAgainTakesANewTokenFirst() {
    XCTAssertEqual(move(.newSession), .newToken(.biometricKyc, resumeAt: .flow))
  }

  func testCloseLeavesTheRun() {
    XCTAssertEqual(move(.exit), .leave)
  }

  func testARunWhoseProductWasNotKeptCanOnlyLeave() {
    for action in UseSmileIDSampleErrorAction.allCases {
      let move = useSmileIDSampleErrorMove(action, product: nil, sessionLive: true, livePartnerId: "p", runPartnerId: "p")
      XCTAssertEqual(move, .leave, action.rawValue)
    }
  }

  private func move(
    _ action: UseSmileIDSampleErrorAction,
    sessionLive: Bool = true,
    livePartnerId: String? = "partner_1",
    runPartnerId: String? = "partner_1"
  ) -> UseSmileIDSampleErrorMove {
    useSmileIDSampleErrorMove(action, product: .biometricKyc, sessionLive: sessionLive, livePartnerId: livePartnerId, runPartnerId: runPartnerId)
  }
}
