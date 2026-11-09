@testable import SampleUI
import XCTest

/// The SUBMISSION section's switches: config.skipApiSubmission and config.allowOfflineMode, off as the SDK defaults them.
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

  func testOfflineModeIsOffByDefaultAndItsSwitchMovesNoOtherRow() {
    let defaults = UseSmileIDSampleSettings()
    XCTAssertFalse(defaults.allowOfflineMode)

    var expected = defaults
    expected.allowOfflineMode = true
    XCTAssertEqual(defaults.with(.allowOfflineMode, true), expected)
  }

  func testTheOfflineSwitchIsStoredUnderTheAndroidKey() {
    XCTAssertEqual(UseSmileIDSampleSetting.allowOfflineMode.storageKey, "allow_offline_mode")
    XCTAssertEqual(UseSmileIDSampleTestIds.settingAllowOfflineMode, "sample_setting_allow_offline_mode")
  }
}
