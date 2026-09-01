import XCTest

/// The app's first test that drives the real shell. Every later screen asserts its route here for
/// one line rather than a new harness.
final class UseSmileIDSampleNavigationUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  func testALinkOpensAScreenInAnotherTab() {
    open("verifications")
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
  }

  /// The two-level case: `profiles/{id}` seats `profileConfig` under `profiles`. Only the first
  /// level arrives — a defect that predates the nav container change and reproduces on `main`, so
  /// it is recorded rather than fixed here. Remove the expectation with the fix; see §7 of the plan.
  func testALinkOpensATwoLevelRouteInAnotherTab() {
    open("profiles/demo")
    let deepest = app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "profileConfig")
    ).firstMatch
    // Scoped to this assertion alone: unscoped, it would also absorb a delivery failure raised by
    // `open`, and a total regression would report as the limitation already known about.
    XCTExpectFailure("nested links do not chain on the iOS 15 NavigationView idiom") {
      XCTAssertTrue(deepest.waitForExistence(timeout: 10), "the pushed level did not arrive")
    }
  }

  func testTheNavPillSwitchesTabs() {
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_sign_out").waitForExistence(timeout: 10))
  }

  /// The leak this shell was restructured to close: a tab that is not showing must not answer.
  func testOnlyTheShowingTabsIdsAreQueryable() {
    // Each id is proven present before it is asserted gone; asserting absence alone passes just as
    // well when the id never existed.
    XCTAssertTrue(element("sample_product_card_smartSelfieEnrollment").waitForExistence(timeout: 10))
    element("sample_nav_verifications").tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    // Waited for, not read once: the outgoing subtree lives for the length of the transition, so an
    // instant read reds the lane whenever the tap and the query interleave differently.
    XCTAssertTrue(element("sample_product_card_smartSelfieEnrollment").waitForNonExistence(timeout: 5))
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_sign_out").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_verifications_screen").waitForNonExistence(timeout: 5))
    XCTAssertTrue(element("sample_product_card_smartSelfieEnrollment").waitForNonExistence(timeout: 5))
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
  }

  /// `simctl openurl` raises a system confirmation that swallows the link; this is the delivery that
  /// does not, and the prompt is taken if a runtime still shows one.
  private func open(_ path: String) {
    XCUIDevice.shared.system.open(URL(string: "usesmileid-sample-ios://\(path)")!)
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let confirm = springboard.buttons["Open"]
    if confirm.waitForExistence(timeout: 2) {
      confirm.tap()
    }
    // Says which half broke: a second app declaring the same scheme takes the link instead, and
    // the screen assertion alone reads as a routing bug in this app.
    XCTAssertTrue(
      app.wait(for: .runningForeground, timeout: 10),
      "the link did not reach this app — another installed app may claim the scheme"
    )
  }
}
