import SampleUI
@testable import UseSmileIDSample
import XCTest

/// The branch table between `GET /v3/status` and what the screen says. Pure, so none of it needs a
/// network — the same table the Compose adapter is tested against.
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

  private func outcome(
    _ status: String,
    message: String = "Approved",
    code: Int = 200
  ) -> UseSmileIDSampleStatusRefresh {
    useSmileIDSampleStatusOutcome(
      code: code,
      body: UseSmileIDSampleStatusResponse(
        status: status,
        jobId: "job-1",
        userId: "user-1",
        message: message,
        createdAt: "2026-07-16T11:50:12.000Z"
      )
    )
  }
}
