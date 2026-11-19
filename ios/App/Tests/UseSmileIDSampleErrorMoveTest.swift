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

  func testFixingTheInputOnAnotherPartnerStartsFromTheFirstStepWithFreshForms() {
    XCTAssertEqual(move(.fixInput, livePartnerId: "partner_2"), .runFromStart(.biometricKyc))
  }

  func testFixingInputTheTokenCarriesTakesANewTokenAndAProductWithNoIdFormStartsAgain() {
    XCTAssertEqual(move(.fixInput, idDetails: .token), .newToken(.biometricKyc, resumeAt: .firstStep))
    XCTAssertEqual(move(.fixInput, idDetails: .none), .runFromStart(.biometricKyc))
  }

  func testStartingAgainTakesANewTokenFirst() {
    XCTAssertEqual(move(.newSession), .newToken(.biometricKyc, resumeAt: .flow))
  }

  func testCloseLeavesTheRun() {
    XCTAssertEqual(move(.exit), .leave)
  }

  func testOnceAnotherProductTapHasResetTheFormsEveryMoveStartsTheProductAfresh() {
    for action in [UseSmileIDSampleErrorAction.retry, .retryLater, .recapture] {
      XCTAssertEqual(move(action, formsHoldRun: false), .runFromStart(.biometricKyc), action.rawValue)
      XCTAssertEqual(move(action, sessionLive: false, formsHoldRun: false), .newToken(.biometricKyc, resumeAt: .firstStep), action.rawValue)
    }
    XCTAssertEqual(move(.fixInput, formsHoldRun: false), .runFromStart(.biometricKyc))
    XCTAssertEqual(move(.newSession, formsHoldRun: false), .newToken(.biometricKyc, resumeAt: .firstStep))
  }

  func testARunWhoseProductWasNotKeptCanOnlyLeave() {
    for action in UseSmileIDSampleErrorAction.allCases {
      let move = useSmileIDSampleErrorMove(action, product: nil, sessionLive: true, livePartnerId: "p", runPartnerId: "p", idDetails: .form, formsHoldRun: true)
      XCTAssertEqual(move, .leave, action.rawValue)
    }
  }

  private func move(
    _ action: UseSmileIDSampleErrorAction,
    sessionLive: Bool = true,
    livePartnerId: String? = "partner_1",
    runPartnerId: String? = "partner_1",
    idDetails: UseSmileIDSampleIdDetailsSource = .form,
    formsHoldRun: Bool = true
  ) -> UseSmileIDSampleErrorMove {
    useSmileIDSampleErrorMove(
      action,
      product: .biometricKyc,
      sessionLive: sessionLive,
      livePartnerId: livePartnerId,
      runPartnerId: runPartnerId,
      idDetails: idDetails,
      formsHoldRun: formsHoldRun
    )
  }
}
