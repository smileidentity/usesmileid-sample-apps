@testable import SampleUI
import XCTest

/// A details link opens before the store reports, so "not loaded yet" must not read as "no such verification".
final class UseSmileIDSampleVerificationDetailsStateTest: XCTestCase {
  func testAJobStillLoadingIsNotMissing() {
    XCTAssertFalse(UseSmileIDSampleVerificationDetailsState(jobId: "job_1", pending: true).missing)
  }

  func testAJobTheStoreDoesNotHaveIsMissing() {
    XCTAssertTrue(UseSmileIDSampleVerificationDetailsState(jobId: "job_1").missing)
  }
}
