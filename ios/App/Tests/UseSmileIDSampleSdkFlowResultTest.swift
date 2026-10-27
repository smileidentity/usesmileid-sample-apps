import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

/// What the result card records for each terminal result, and what the sample does with a captured job.
final class UseSmileIDSampleSdkFlowResultTest: XCTestCase {
  private var session: URL!

  override func setUpWithError() throws {
    try super.setUpWithError()
    session = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: session, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: session)
    try super.tearDownWithError()
  }

  func testACapturedJobIsRecordedAsCapturedNotAsAFailure() {
    var flow = UseSmileIDSampleFlowResult()

    flow.record(UseSmileIDResult<JobSubmissionResponse>.captured(capturedJob()))

    XCTAssertEqual(flow.status, .captured)
    XCTAssertNil(flow.lastError)
    XCTAssertNil(flow.jobId, "nothing was submitted, so there is no job id")
    XCTAssertEqual(flow.resultCallbackCount, 1)
  }

  func testACapturedJobsFilesAndSessionDirectoryAreDeletedSinceThisSampleForwardsNothing() throws {
    let selfie = session.appendingPathComponent("selfie.jpg")
    let liveness = session.appendingPathComponent("liveness.jpg")
    try Data("selfie".utf8).write(to: selfie)
    try Data("liveness".utf8).write(to: liveness)
    try Data("{}".utf8).write(to: session.appendingPathComponent("left-over.json"))
    let front = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-front.jpg")
    try Data("front".utf8).write(to: front)

    capturedJob(selfie: selfie, liveness: [liveness], front: front).deleteFiles()

    XCTAssertFalse(FileManager.default.fileExists(atPath: session.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: front.path), "a listed file outside the session directory goes too")
  }

  private func capturedJob(selfie: URL? = nil, liveness: [URL] = [], front: URL? = nil) -> CapturedJob {
    CapturedJob(
      jobType: .smartSelfieEnrollment,
      sessionId: "session",
      sessionDirectory: session,
      selfieImage: selfie,
      livenessImages: liveness,
      frontDocument: front,
      backDocument: nil,
      visaDocument: nil,
      headers: [:],
      encryptedPackage: "00",
      packageNonce: "00",
      packageTag: "00"
    )
  }
}
