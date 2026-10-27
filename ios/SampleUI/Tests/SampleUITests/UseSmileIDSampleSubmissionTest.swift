@testable import SampleUI
import XCTest

/// The Skip API submission switch: config.skipApiSubmission, off as the SDK defaults it.
final class UseSmileIDSampleSubmissionTest: XCTestCase {
  func testTheSdkSubmitsByDefaultAndTheSwitchMovesNoOtherRow() {
    let defaults = UseSmileIDSampleSettings()
    XCTAssertFalse(defaults.skipApiSubmission)

    var expected = defaults
    expected.skipApiSubmission = true
    XCTAssertEqual(defaults.with(.skipApiSubmission, true), expected)
  }

  func testTheSwitchIsStoredUnderTheAndroidKey() {
    XCTAssertEqual(UseSmileIDSampleSetting.skipApiSubmission.storageKey, "skip_api_submission")
    XCTAssertEqual(UseSmileIDSampleTestIds.settingSkipApiSubmission, "sample_setting_skip_api_submission")
  }
}
