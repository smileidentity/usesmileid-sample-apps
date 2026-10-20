import XCTest

/// Anchors `Bundle(for:)` to this test bundle, whose Info.plist carries the scheme.
private final class UseSmileIDSampleLinkBundle {}

extension XCUIApplication {
  /// Opens a link on the host's scheme; `simctl openurl` raises a confirmation that swallows it, this takes the prompt if shown.
  func useSmileIDSampleOpen(_ path: String) {
    let key = "UseSmileIDSampleURLScheme"
    guard let scheme = Bundle(for: UseSmileIDSampleLinkBundle.self).object(forInfoDictionaryKey: key) as? String,
          !scheme.isEmpty
    else {
      XCTFail("\(key) is missing from the runner's Info.plist — set USESMILEID_SAMPLE_URL_SCHEME on the project")
      return
    }
    XCUIDevice.shared.system.open(URL(string: "\(scheme)://\(path)")!)
    let confirm = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Open"]
    if confirm.waitForExistence(timeout: 2) {
      confirm.tap()
    }
    XCTAssertTrue(
      wait(for: .runningForeground, timeout: 10),
      "the link did not reach this app — another installed app may claim the scheme"
    )
  }
}
