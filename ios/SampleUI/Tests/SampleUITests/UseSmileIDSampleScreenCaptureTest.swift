@testable import SampleUI
import XCTest

/// The Allow screen capture switch: config.allowScreenCapture, on in the sample where the SDK defaults it off.
final class UseSmileIDSampleScreenCaptureTest: XCTestCase {
  func testTheSampleAllowsScreenCaptureByDefaultAndTheSwitchMovesNoOtherRow() {
    let defaults = UseSmileIDSampleSettings()
    XCTAssertTrue(defaults.allowScreenCapture)

    var expected = defaults
    expected.allowScreenCapture = false
    XCTAssertEqual(defaults.with(.allowScreenCapture, false), expected)
  }

  func testTheSwitchIsStoredUnderTheAndroidKey() {
    XCTAssertEqual(UseSmileIDSampleSetting.allowScreenCapture.storageKey, "allow_screen_capture")
    XCTAssertEqual(UseSmileIDSampleTestIds.settingAllowScreenCapture, "sample_setting_allow_screen_capture")
  }
}
