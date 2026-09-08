import XCTest

/// The SDK flow host: the opener `AGENTS.md` asks of every device flow, both presentations, and the
/// gate's three exits.
///
/// What the simulator can prove stops at the shutter. Consent is an SDK screen with no camera, and
/// Deny and a back-out are both terminal, so the mount, the result transition and the exactly-once
/// claim are all provable here. A success is not: it needs a 202 from the server, which needs a real
/// Portal token — see `docs/plan/ios-device-verification.md` §2.3.
final class UseSmileIDSampleFlowUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  /// The launch-integrity opener: launch, the product list, then the SDK mounted. A packaging failure
  /// fails here conclusively instead of looking like a UI defect further in.
  func testTheOpenerLaunchesToTheProductListAndAProductMountsTheSdk() {
    launch()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    startEnrollment()
    XCTAssertTrue(
      element("si_consent_screen").waitForExistence(timeout: 20),
      "the SDK did not mount — check that the XCFramework and its analyzers shipped with this build"
    )
    XCTAssertTrue(app.buttons["si_deny_button"].exists, "the SDK's own controls are not queryable")
  }

  /// R4: the result replaces the flow and both forms rather than stacking over them, and exactly one
  /// terminal result is recorded. Deny is a Failure, not a cancel — the SDK never conflates them.
  func testDenyingConsentDeliversOneResultAndReplacesTheFlow() {
    launch()
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))
    app.buttons["si_deny_button"].tap()

    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("si_consent_screen").waitForNonExistence(timeout: 5), "the flow is still mounted")
    XCTAssertEqual(element("sample_result_result_count").label, "1", "the callback did not arrive exactly once")
    XCTAssertEqual(element("sample_result_job_status").label, "failed", "a denial is a failure, not a cancel")
    // No server-issued job id, so the landing route carries the stable non-id and says so.
    XCTAssertTrue(element("sample_details_empty").exists)

    // Back never goes into capture: back lands on the tab the result belongs to, and the flow's own
    // tab is at its root.
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_user_details_screen").waitForNonExistence(timeout: 5), "the form is still stacked")
  }

  /// R5: backing out of the SDK's first screen is a cancellation the SDK delivers itself, and
  /// removing the flow from the hierarchy is all the host does about it — never a cancel of its own.
  ///
  /// A token that binds consent is what makes this reachable: it lifts the consent screen, so the
  /// first screen is instructions, which carries the SDK's own back control. Consent deliberately has
  /// none, because it has to be answered, and turning its switch off instead leaves the run with no
  /// source of consent at all — which the gate blocks. The platform's edge swipe is the other way
  /// out, and it is not provable on this lane: XCUITest's synthesised drag does not drive
  /// `UIScreenEdgePanGestureRecognizer`, falsified against a host screen that did not pop either.
  /// See `docs/plan/ios-device-verification.md` §2.3.
  func testBackingOutOfTheSdksFirstScreenCancelsAndCreatesNoJob() {
    launch()
    let rowsBefore = allVerificationsCount()
    linkASessionThatBindsConsent()
    startEnrollment()

    XCTAssertTrue(
      element("si_instructions_screen").waitForExistence(timeout: 20),
      "the SDK's first screen is not the one with a back control"
    )
    XCTAssertFalse(element("si_consent_screen").exists, "the token's consent binding did not lift the screen")
    // By label: at 12.0.2 the instructions screen carries `si_instructions_screen` on a container,
    // which overrides every control's own identifier — the same trap this app's own screens avoid.
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10), "the cancel did not leave the flow")

    XCTAssertEqual(allVerificationsCount(), rowsBefore, "a cancelled run must create no row")
    // The card is the only surface that publishes the counters, and a finished run shows no line on
    // products, so it is read where a link can always reach it.
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_result_count").label, "1", "the cancel did not arrive exactly once")
    XCTAssertEqual(element("sample_result_job_status").label, "cancelled")
  }

  /// R6, for the one thing the flow host owns: the run is a `@StateObject` whose identity is the
  /// route, so a rotation must keep it rather than start a second one.
  func testRotatingWhileTheFlowIsMountedKeepsTheSameRun() {
    launch()
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))

    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 10), "the flow did not survive the rotation")
    // Or the assertion above passes vacuously: a device that never turned proves nothing about a
    // rotation, and an app the SDK has locked to portrait is what that would look like.
    let window = app.windows.element(boundBy: 0).frame
    XCTAssertGreaterThan(window.width, window.height, "the app did not rotate, so nothing was rebuilt")

    // The same run, not a second one: a restart would have re-run the gate and the counters with it.
    app.buttons["si_deny_button"].tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_result_count").label, "1", "the rotation started a second run")
  }

  /// §7.3's cold-link gate: a link straight at the run with nothing typed must not reach the SDK, and
  /// the form it redirects to is the one the wizard would have asked for.
  func testALinkIntoTheRunWithNothingTypedRedirectsToTheForm() {
    launch()
    open("flow/biometricKyc/run")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("si_consent_screen").waitForNonExistence(timeout: 5), "an empty payload reached the SDK")
  }

  /// The gate's session exit, and the reason it hands the screen it lands on (R10). An Expired
  /// simulated span is the only way to reach it without waiting for a real token to run out.
  func testAnEndedSessionSendsTheRunToTheScannerAndRelinkingResumesTheRun() {
    launch()
    linkAnExpiredSession()
    startEnrollment()

    XCTAssertTrue(element("sample_scan_token_screen").waitForExistence(timeout: 10), "the run reached the SDK anyway")
    XCTAssertTrue(
      app.staticTexts["Token session ended. Scan to continue where you left off."].exists,
      "the scanner did not say why it opened"
    )

    // Relinking a live token re-enters the run the gate interrupted.
    app.buttons["15m"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20), "the run did not resume")
    XCTAssertTrue(element("sample_scan_token_screen").waitForNonExistence(timeout: 5), "the scanner is still stacked")
  }

  /// R3's second presentation, which is the one that exposes host chrome and insets. The launch
  /// argument is what carries it through the wizard: a link's `route` cannot survive the gate's
  /// redirect, and no continuation may become a route argument (§8.3).
  func testTheInShellPresentationRunsAndReportsItsRoute() {
    launch(arguments: ["-route", "shell"])
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20), "the in-shell flow did not mount")
    app.buttons["si_deny_button"].tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_route").label, "shell")
  }

  /// The opener's second half: re-entry by rapid taps is one run and one terminal result. The runner
  /// serialises its events, so the second tap lands after the push rather than beside it — what this
  /// proves is that a tap arriving on the mounted flow starts nothing. That two pushes of the same
  /// route keep one level is the router's own test, where it is deterministic.
  func testRapidTapsOnContinueStartOneRunWithOneResult() {
    launch()
    fillTheDetailsForm()
    // The button's own centre, anchored on the app rather than on the button: a coordinate resolves
    // its element on every tap, so the second tap would look for a control the first has already
    // navigated away from. The point still comes from the id, never from the screen.
    let button = app.buttons["sample_user_details_continue"]
    XCTAssertTrue(button.waitForExistence(timeout: 10))
    let centre = CGVector(dx: button.frame.midX, dy: button.frame.midY)
    let target = app.coordinate(withNormalizedOffset: .zero).withOffset(centre)
    target.tap()
    target.tap()

    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))
    app.buttons["si_deny_button"].tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_result_count").label, "1", "two taps started two runs")
    XCTAssertTrue(element("si_consent_screen").waitForNonExistence(timeout: 5), "a second flow is still stacked")
  }

  // MARK: - Journeys

  /// Products → the details form → the run, the way a reader reaches it.
  private func startEnrollment() {
    fillTheDetailsForm()
    app.buttons["sample_user_details_continue"].tap()
  }

  private func fillTheDetailsForm() {
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    element("sample_product_card_smartSelfieEnrollment").tap()
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    type("sample_user_details_field_firstName", "Kwame")
    type("sample_user_details_field_lastName", "Asante")
    type("sample_user_details_field_email", "kwame@uptech.example")
  }

  /// A live token whose consent claim lifts the SDK's consent screen, so the run starts at
  /// instructions.
  private func linkASessionThatBindsConsent() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    app.buttons["SIMULATED SCAN"].tap()
    XCTAssertTrue(app.buttons["Binds consent"].waitForExistence(timeout: 5))
    app.buttons["Binds consent"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_card").waitForExistence(timeout: 10))
  }

  /// Links a token that is already spent, which is the state the gate refuses.
  private func linkAnExpiredSession() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    app.buttons["SIMULATED SCAN"].tap()
    XCTAssertTrue(app.buttons["Expired"].waitForExistence(timeout: 5))
    app.buttons["Expired"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_ended_banner").waitForExistence(timeout: 10))
  }

  /// Compared before and after rather than asserted at zero: the rows persist on the simulator by
  /// design, so what a run must not do is add one.
  private func allVerificationsCount() -> String {
    element("sample_nav_verifications").tap()
    let count = element("sample_filter_count_all")
    XCTAssertTrue(count.waitForExistence(timeout: 10))
    let label = count.label
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    return label
  }

  // MARK: - Harness

  /// The session is a Keychain record that outlives an uninstall, so a test that linked one would
  /// otherwise hand it to every test after it — and an ended marker sends every later run to the
  /// scanner.
  private func launch(arguments: [String] = []) {
    app.launchArguments = arguments
    app.launch()
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
    guard element("sample_session_card").exists || element("sample_session_ended_banner").exists else { return }
    signOut()
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_session_card").waitForNonExistence(timeout: 5))
  }

  /// Reached from the settings root; the row sits below the fold on the pinned simulator.
  private func signOut() {
    element("sample_nav_settings").tap()
    let signOut = element("sample_sign_out")
    XCTAssertTrue(signOut.waitForExistence(timeout: 10))
    for _ in 0..<4 where !signOut.isHittable {
      app.swipeUp()
    }
    signOut.tap()
  }

  private func type(_ id: String, _ text: String) {
    let field = app.textFields[id]
    XCTAssertTrue(field.waitForExistence(timeout: 5), id)
    field.tap()
    field.typeText(text)
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
    XCTAssertTrue(
      app.wait(for: .runningForeground, timeout: 10),
      "the link did not reach this app — another installed app may claim the scheme"
    )
  }
}
