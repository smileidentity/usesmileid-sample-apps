import SampleUI
@testable import UseSmileIDSample
import XCTest

/// The branch table between `GET /v3/status` and what the screen says; pure, so none of it needs a network.
final class UseSmileIDSampleStatusOutcomeTest: XCTestCase {
  func testTheFiveApiStatesLandOnTheFourBadgesTheDesignDraws() {
    XCTAssertEqual(outcome("clear"), .updated(status: .clear, message: "Approved", httpCode: 200))
    XCTAssertEqual(outcome("attention"), .updated(status: .attention, message: "Approved", httpCode: 200))
    XCTAssertEqual(outcome("block"), .updated(status: .blocked, message: "Approved", httpCode: 200))
    // `error` has no badge of its own, so it lands on Blocked and leans on the server's message.
    XCTAssertEqual(outcome("error"), .updated(status: .blocked, message: "Approved", httpCode: 200))
    XCTAssertEqual(outcome("processing"), .stillProcessing)
  }

  func testAnUnrecognisedStatusIsReportedRatherThanGuessed() {
    XCTAssertEqual(outcome("quarantined"), .failed(reason: "Unrecognised status 'quarantined'"))
  }

  func testANonSuccessCodeIsAFailureWhateverTheBodySays() {
    XCTAssertEqual(outcome("clear", code: 401), .failed(reason: "HTTP 401"))
    XCTAssertEqual(outcome("clear", code: 500), .failed(reason: "HTTP 500"))
  }

  func testAMissingBodyIsAFailureCarryingTheCode() {
    XCTAssertEqual(
      useSmileIDSampleStatusOutcome(code: 200, body: nil),
      .failed(reason: "HTTP 200")
    )
  }

  func testTheServersMessageIsCarriedThrough() {
    XCTAssertEqual(
      outcome("attention", message: "Provisional — needs review"),
      .updated(status: .attention, message: "Provisional — needs review", httpCode: 200)
    )
  }

  /// Only `status` and `message` are read, so a 2xx missing any of the rest is still an outcome.
  func testABodyCarryingOnlyWhatIsConsumedIsStillAnOutcome() throws {
    let json = #"{"status":"clear","message":"Approved"}"#
    let body = try JSONDecoder().decode(UseSmileIDSampleStatusResponse.self, from: Data(json.utf8))
    XCTAssertEqual(
      useSmileIDSampleStatusOutcome(code: 200, body: body),
      .updated(status: .clear, message: "Approved", httpCode: 200)
    )
  }

  func testTheResponseDecodesTheApiSnakeCaseKeys() throws {
    let json = """
    {"status":"clear","job_id":"job-1","user_id":"user-1","message":"Approved",
     "created_at":"2026-07-16T11:50:12.000Z","added_by_the_server":true}
    """
    let body = try JSONDecoder().decode(UseSmileIDSampleStatusResponse.self, from: Data(json.utf8))
    XCTAssertEqual(body.jobId, "job-1")
    XCTAssertEqual(body.userId, "user-1")
    XCTAssertEqual(body.createdAt, "2026-07-16T11:50:12.000Z")
  }

  func testTheJobIdIsEncodedAsOnePathSegment() {
    XCTAssertEqual(
      useSmileIDSampleStatusUrl(jobId: "job_00ky31za00", sandbox: true)?.absoluteString,
      "https://testapi.smileidentity.com/v3/status/job_00ky31za00"
    )
    // The route that reads a stored id is a deep link, so nothing may escape the segment it was given.
    for hostile in ["../../v2/oops", "job?x=1", "job#frag", "job 1"] {
      let url = useSmileIDSampleStatusUrl(jobId: hostile, sandbox: true)
      XCTAssertEqual(url?.host, "testapi.smileidentity.com", hostile)
      XCTAssertEqual(url?.pathComponents.count, 4, "\(hostile) left the segment")
      XCTAssertNil(url?.query, hostile)
      XCTAssertNil(url?.fragment, hostile)
    }
  }

  func testTheEnvironmentComesFromTheRowsOwnFlag() {
    XCTAssertEqual(useSmileIDSampleStatusUrl(jobId: "job-1", sandbox: false)?.host, "api.smileidentity.com")
    XCTAssertEqual(useSmileIDSampleStatusUrl(jobId: "job-1", sandbox: true)?.host, "testapi.smileidentity.com")
  }

  func testAnIdWithNothingLeftToAskAboutIsNoUrlAtAll() {
    XCTAssertNil(useSmileIDSampleStatusUrl(jobId: "", sandbox: true))
  }

  private func outcome(
    _ status: String,
    message: String = "Approved",
    code: Int = 200
  ) -> UseSmileIDSampleStatusRefresh {
    useSmileIDSampleStatusOutcome(
      code: code,
      body: UseSmileIDSampleStatusResponse(
        status: status,
        message: message,
        jobId: "job-1",
        userId: "user-1",
        createdAt: "2026-07-16T11:50:12.000Z"
      )
    )
  }
}
