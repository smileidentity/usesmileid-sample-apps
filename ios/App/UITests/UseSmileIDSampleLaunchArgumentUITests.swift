import XCTest

/// The launch arguments, read through UserDefaults, and what the card says the run actually got.
/// Launches per test, because the arguments are the subject.
final class UseSmileIDSampleLaunchArgumentUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  /// The card reports the run it got, not the argument that was passed — and every value is text.
  func testTheArgumentsSeedTheCard() {
    launch(["-scenario", "badRefresh", "-theme", "partnerOverride", "-route", "shell", "-probes", "true"])
    openDetails()
    XCTAssertEqual(element("sample_result_active_scenario").label, "badRefresh")
    XCTAssertEqual(element("sample_result_active_theme").label, "partnerOverride")
    XCTAssertEqual(element("sample_result_route").label, "shell")
  }

  /// An unrecognised value falls back to its default, which is safe only because the card says so.
  func testAnUnrecognisedValueReadsAsTheDefaultOnTheCard() {
    launch(["-scenario", "typo", "-route", "sheet", "-probes", "true"])
    openDetails()
    XCTAssertEqual(element("sample_result_active_scenario").label, "normal")
    XCTAssertEqual(element("sample_result_route").label, "fullscreen")
  }

  /// The argument seeds the first launch only: a drawer choice wins for the rest of the run, and a
  /// relaunch with other arguments is a fresh run, restoring nothing.
  func testTheDrawerWinsOverTheArgumentAndARelaunchIsAFreshRun() {
    launch(["-scenario", "expiredToken", "-probes", "true"])
    open("debug/scenarios")
    XCTAssertTrue(element("sample_scenario_drawer").waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["sample_scenario_item_expiredToken"].isSelected, "the argument did not reach the drawer")
    app.buttons["sample_scenario_item_offlineRetry"].tap()
    openDetails()
    XCTAssertEqual(element("sample_result_active_scenario").label, "offlineRetry")

    app.terminate()
    launch(["-scenario", "throwingCallback", "-probes", "true"])
    openDetails()
    XCTAssertEqual(element("sample_result_active_scenario").label, "throwingCallback")
  }

  /// `probes` reveals the card on a release build; debug always shows it. The release lane names its
  /// configuration, and there the Settings DEBUG row must be gone too; anywhere else the row says which
  /// build this is, since it is compiled out of release on every platform.
  func testWithoutTheArgumentTheCardFollowsTheBuild() {
    launch([])
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_sign_out").waitForExistence(timeout: 10))
    let debugRow = element("sample_scenario_drawer_button").exists
    let release = ProcessInfo.processInfo.environment["USESMILEID_SAMPLE_CONFIGURATION"] == "Release"
    if release {
      XCTAssertFalse(debugRow, "the DEBUG row leaked into a release build")
    }
    let debugBuild = release ? false : debugRow
    openDetails(expectingCard: debugBuild)
    if debugBuild {
      XCTAssertTrue(element("sample_result_card").exists, "a debug build always shows the card")
    } else {
      // Waited for, not read once: an absence read on arrival passes even if the card lands a frame later.
      XCTAssertFalse(
        element("sample_result_card").waitForExistence(timeout: 3),
        "a release build hides the card without -probes"
      )
    }
  }

  /// A plain launch carries one empty profile whose row reads as a placeholder, never a fixture.
  func testAPlainLaunchCarriesOneEmptyProfile() {
    launch([])
    open("profiles")
    XCTAssertTrue(element("sample_profile_row_p-1").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["Default profile"].exists)
    XCTAssertTrue(app.staticTexts["No user details yet \u{00B7} active"].exists)
    XCTAssertFalse(element("sample_profile_row_p-2").exists, "a fixture arrived without seedProfiles")
    XCTAssertFalse(app.staticTexts["PesaLink"].exists)
  }

  func testSeedProfilesCarriesTheDesignsThree() {
    launch(["-seedProfiles", "true"])
    open("profiles")
    XCTAssertTrue(element("sample_profile_row_p-3").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["PesaLink"].exists)
    XCTAssertTrue(app.staticTexts["Kwame Asante \u{00B7} active"].exists)
    XCTAssertFalse(app.staticTexts["Default profile"].exists, "the starter must not sit among the fixtures")
  }

  func testWithTheArgumentTheCardShowsOnAnyBuild() {
    launch(["-probes", "true"])
    openDetails()
    XCTAssertTrue(element("sample_result_result_count").exists)
  }

  private func launch(_ arguments: [String]) {
    app.launchArguments = arguments
    app.launch()
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
  }

  /// The details route with no job is where the card is and nothing else changes.
  private func openDetails(expectingCard: Bool = true) {
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_details_empty").waitForExistence(timeout: 10))
    if expectingCard {
      XCTAssertTrue(element("sample_result_card").waitForExistence(timeout: 10))
    }
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
  }

  private func open(_ path: String) {
    XCUIDevice.shared.system.open(URL(string: "usesmileid-sample-ios://\(path)")!)
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let confirm = springboard.buttons["Open"]
    if confirm.waitForExistence(timeout: 2) {
      confirm.tap()
    }
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "the link did not reach this app")
  }
}
