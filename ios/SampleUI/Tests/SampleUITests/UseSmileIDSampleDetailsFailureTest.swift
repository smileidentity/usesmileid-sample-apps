import Foundation
@testable import SampleUI
import XCTest

/// Which failure verification details states, and how its banner reads.
final class UseSmileIDSampleDetailsFailureTest: XCTestCase {
  private let serverError = UseSmileIDSampleErrorHandling.forStatus(503)

  func testARunThatFailedBeforeAnyJobStatesItsOwnRow() {
    XCTAssertEqual(useSmileIDSampleDetailsFailure(job: nil, landedRun: serverError), serverError)
  }

  func testAFailedRunNoSubmissionExplainsStatesTheSubmissionFallback() {
    XCTAssertEqual(useSmileIDSampleLandedFailure(status: .failed, row: nil)?.id, "requestInvalid")
  }

  func testARunThatDidNotFailLandsWithNoFailure() {
    for status in [UseSmileIDSampleFlowStatus.captured, .succeeded, .cancelled] {
      XCTAssertNil(useSmileIDSampleLandedFailure(status: status, row: serverError), status.id)
    }
    XCTAssertEqual(useSmileIDSampleLandedFailure(status: .failed, row: serverError), serverError)
  }

  func testAMissingJobWithNoFailedRunStatesNothing() {
    XCTAssertNil(useSmileIDSampleDetailsFailure(job: nil, landedRun: nil))
  }

  func testAJobThatEndedInErrorOrBlockStatesTheFallbackUntilTheStatusCarriesAReason() {
    for status in [UseSmileIDSampleStatus.error, .blocked] {
      XCTAssertEqual(useSmileIDSampleDetailsFailure(job: job(status), landedRun: serverError)?.id, "notVerified", status.rawValue)
    }
  }

  func testAJobWithAnyOtherStatusStatesNothingEvenAfterAFailedRun() {
    for status in [UseSmileIDSampleStatus.clear, .attention, .processing] {
      XCTAssertNil(useSmileIDSampleDetailsFailure(job: job(status), landedRun: serverError), status.rawValue)
    }
  }

  func testAFailureTryingAgainLaterCanGetPastIsAWarningAndAFinalOneAnError() {
    XCTAssertEqual(serverError.bannerTone, .warning)
    XCTAssertEqual(UseSmileIDSampleErrorHandling.forReason(nil).bannerTone, .error)
  }

  func testAFailedRunIsNotDrawnAsMissing() {
    let state = UseSmileIDSampleVerificationDetailsState(jobId: "unsubmitted", landedFailure: serverError)
    XCTAssertEqual(state.failure, serverError)
    XCTAssertFalse(state.missing)
  }

  private func job(_ status: UseSmileIDSampleStatus) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: "job_1",
      userId: "user_1",
      product: .biometricKyc,
      status: status,
      createdAt: Date(timeIntervalSince1970: 0),
      message: "Rejected",
      httpStatus: 200
    )
  }
}
