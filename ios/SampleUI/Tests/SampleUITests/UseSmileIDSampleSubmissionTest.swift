@testable import SampleUI
import XCTest

/// config.skipApiSubmission's two values, picked from a sheet like the capture mode.
final class UseSmileIDSampleSubmissionTest: XCTestCase {
  func testOnlySkipTurnsOnSkipApiSubmissionAndTheDefaultSubmits() {
    XCTAssertEqual(UseSmileIDSampleSettings().submission, .submit)
    XCTAssertFalse(UseSmileIDSampleSubmission.submit.skipsApiSubmission)
    XCTAssertTrue(UseSmileIDSampleSubmission.skip.skipsApiSubmission)
  }

  func testEachChoiceIsNamedAsTheSpecSaysAndKeyedByItsTestId() {
    XCTAssertEqual(UseSmileIDSampleSubmission.allCases.map(\.rawValue), ["submit", "skip"])
    XCTAssertEqual(UseSmileIDSampleSubmission.submit.label, "Submit to Smile ID")
    XCTAssertEqual(UseSmileIDSampleSubmission.skip.label, "Skip API submission")
    XCTAssertEqual(UseSmileIDSampleTestIds.submissionOption("skip"), "sample_submission_option_skip")
  }
}
