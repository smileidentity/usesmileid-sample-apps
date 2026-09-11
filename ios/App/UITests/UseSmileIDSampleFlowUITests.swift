import XCTest

/// The flow host on the simulator, which stops at the shutter: the mount, both presentations, the gate's exits, a deny and a back-out.
final class UseSmileIDSampleFlowUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  /// Set by a test running on a SCANNED session, which signing out would cost a real token.
  private var preservesSession = false

  /// The session and the pushed stack both outlive this class, so they are left as found or the next class inherits them.
  override func tearDown() {
    // Only when it is actually rotated: a killed runner never reaches the rotating test's `defer`, and the simulator keeps it.
    if XCUIDevice.shared.orientation != .portrait {
      XCUIDevice.shared.orientation = .portrait
    }
    if app.state == .runningForeground {
      atATabRoot()
      if !preservesSession,
         element("sample_session_card").exists || element("sample_session_ended_banner").exists {
        signOut()
        element("sample_nav_products").tap()
      }
    }
    app.terminate()
    super.tearDown()
  }

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

  func testDenyingConsentDeliversOneResultAndReplacesTheFlow() {
    launch()
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))
    app.buttons["si_deny_button"].tap()

    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("si_consent_screen").waitForNonExistence(timeout: 5), "the flow is still mounted")
    XCTAssertEqual(element("sample_result_result_count").label, "1", "the callback did not arrive exactly once")
    XCTAssertEqual(element("sample_result_job_status").label, "failed", "a denial is a failure, not a cancel")
    XCTAssertTrue(element("sample_details_empty").exists)

    // Back never goes into capture: the flow's own tab is at its root.
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_user_details_screen").waitForNonExistence(timeout: 5), "the form is still stacked")
  }

  /// Needs a consent-binding token, since only instructions carries the SDK's back control; XCUITest cannot drive the edge swipe.
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
    // By label: at 12.0.2 that screen's container id overrides every control's own identifier.
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10), "the cancel did not leave the flow")

    XCTAssertEqual(allVerificationsCount(), rowsBefore, "a cancelled run must create no row")
    // The card is the only surface publishing the counters, and a finished run shows none on products.
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_result_count").label, "1", "the cancel did not arrive exactly once")
    XCTAssertEqual(element("sample_result_job_status").label, "cancelled")
  }

  func testRotatingWhileTheFlowIsMountedKeepsTheSameRun() {
    launch()
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))

    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 10), "the flow did not survive the rotation")
    // Or the assertion above passes vacuously against an app locked to portrait.
    let window = app.windows.element(boundBy: 0).frame
    XCTAssertGreaterThan(window.width, window.height, "the app did not rotate, so nothing was rebuilt")

    // The same run, not a second one: a restart would have re-run the gate and the counters with it.
    app.buttons["si_deny_button"].tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_result_count").label, "1", "the rotation started a second run")
  }

  func testALinkIntoTheRunWithNothingTypedRedirectsToTheForm() {
    launch()
    open("flow/biometricKyc/run")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("si_consent_screen").waitForNonExistence(timeout: 5), "an empty payload reached the SDK")
  }

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

  func testAutostartOpensTheFlowRouteOnLaunch() {
    // A plain launch first, to clear a session a previous test left; the argument's own launch lands where the pill is gone.
    launch()
    app.terminate()
    app.launchArguments = useSmileIDSampleSettingsSeed + ["-autostart", "smartSelfieEnrollment"]
    app.launch()
    XCTAssertTrue(
      element("sample_user_details_screen").waitForExistence(timeout: 10),
      "the argument did not open the flow route"
    )
    XCTAssertFalse(element("sample_products_screen").exists)

    type("sample_user_details_field_firstName", "Kwame")
    type("sample_user_details_field_lastName", "Asante")
    type("sample_user_details_field_email", "kwame@uptech.example")
    app.buttons["sample_user_details_continue"].tap()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))
  }

  /// A simulator has no lens to take, so this proves the hold is inert; the contention needs a phone.
  func testHoldingTheCameraDoesNotStopTheRun() {
    launch(arguments: ["-holdCamera", "500"])
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20), "the hold blocked the run")
    app.buttons["si_deny_button"].tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_result_count").label, "1")
  }

  func testTheInShellPresentationRunsAndReportsItsRoute() {
    launch(arguments: ["-route", "shell"])
    startEnrollment()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20), "the in-shell flow did not mount")
    app.buttons["si_deny_button"].tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_route").label, "shell")
  }

  func testRapidTapsOnContinueStartOneRunWithOneResult() {
    launch()
    fillTheDetailsForm()
    // Anchored on the app, not the button: a coordinate re-resolves its element per tap, and the first tap navigates away.
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

  private func linkASessionThatBindsConsent() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    app.buttons["SIMULATED SCAN"].tap()
    XCTAssertTrue(app.buttons["Binds consent"].waitForExistence(timeout: 5))
    app.buttons["Binds consent"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_card").waitForExistence(timeout: 10))
  }

  private func linkAnExpiredSession() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    app.buttons["SIMULATED SCAN"].tap()
    XCTAssertTrue(app.buttons["Expired"].waitForExistence(timeout: 5))
    app.buttons["Expired"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_ended_banner").waitForExistence(timeout: 10))
  }

  /// Compared before and after, not asserted at zero: the rows persist across launches by design.
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

  /// The session outlives an uninstall, so every launch clears it: an ended marker sends every later run to the scanner.
  /// Enhanced KYC on a real session: the one journey with `capture: false`, so it needs no camera.
  func testEnhancedKycOnALiveSessionReachesATerminalResult() throws {
    // Before the skip, not after: a skip returns immediately and the teardown would then sign out
    // the very session this test skipped for, spending a real token to run nothing.
    preservesSession = true
    try XCTSkipUnless(
      ProcessInfo.processInfo.environment["SMILE_LIVE_SESSION"] == "1",
      "needs a token already scanned onto the device; nothing here mints one"
    )
    // Not `launch()`: it signs out the session this needs, and the teardown is told to keep it.
    app.launchArguments = useSmileIDSampleSettingsSeed
    app.launch()
    atATabRoot()
    // `atATabRoot` reaches any tab root; the session card is on Products alone.
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(
      element("sample_session_card").waitForExistence(timeout: 10),
      "no live session on the device — scan a token before running this"
    )

    // The token decides the environment, so an agent inheriting one must say production out loud.
    let chip = element("sample_env_chip")
    if !chip.waitForExistence(timeout: 5) || chip.label != "Sandbox" {
      try XCTSkipUnless(
        ProcessInfo.processInfo.environment["SMILE_ALLOW_PRODUCTION"] == "1",
        "REFUSING TO SUBMIT: the linked token is \(chip.label), not Sandbox. Set SMILE_ALLOW_PRODUCTION=1 only for a test account."
      )
    }

    element("sample_product_card_enhancedKyc").tap()

    // A token binding consent and user details makes the app skip both forms and mount the SDK.
    if element("sample_user_details_screen").waitForExistence(timeout: 10) {
      fillAnyEmptyUserFields()
      app.buttons["sample_user_details_continue"].tap()
    }
    if element("sample_kyc_form_screen").waitForExistence(timeout: 10) {
      element("sample_country_trigger").tap()
      XCTAssertTrue(element("sample_country_sheet").waitForExistence(timeout: 10))
      element("sample_country_option_KE").tap()
      element("sample_idtype_trigger").tap()
      XCTAssertTrue(element("sample_idtype_sheet").waitForExistence(timeout: 10))
      element("sample_idtype_option_nationalId").tap()
      type("sample_idnumber_input", "AO12345678")
      app.buttons["sample_kyc_continue"].tap()
    }

    // A refused submission stops on the SDK's own failure state, still under si_processing_screen, and
    // the host hears nothing until Exit is tapped — so a passive wait here reads a failure as a hang.
    let details = element("sample_verification_details_screen")
    let exit = app.buttons["si_button_exit"]
    // Whichever comes first: `XCTWaiter.wait(for:)` waits for ALL expectations, and only one of these can exist.
    let deadline = Date().addingTimeInterval(180)
    while Date() < deadline, !details.exists, !exit.exists {
      RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    }
    if exit.exists {
      XCTContext.runActivity(named: "SDK reported a failure and waited for Exit") { _ in }
      exit.tap()
    }
    let landed = details.waitForExistence(timeout: 20)
    let status = landed ? element("sample_result_job_status").label : "<never landed>"
    let count = landed ? element("sample_result_result_count").label : "-"
    let jobId = landed && element("sample_result_job_id").exists ? element("sample_result_job_id").label : "-"
    XCTContext.runActivity(named: "terminal state: \(status) | results: \(count) | job: \(jobId)") { _ in }

    XCTAssertTrue(landed, "no terminal result in 180s — the SDK never handed one back")
    XCTAssertEqual(count, "1", "the result callback did not arrive exactly once")
    XCTAssertNotEqual(status, "running", "still running after a terminal landing")
  }

  /// The token supplies what it binds and those rows are disabled; anything still empty is ours to fill.
  private func fillAnyEmptyUserFields() {
    for (id, value) in [
      ("sample_user_details_field_firstName", "Kwame"),
      ("sample_user_details_field_lastName", "Asante"),
      ("sample_user_details_field_email", "kwame@uptech.example")
    ] {
      let field = app.textFields[id]
      guard field.exists, field.isEnabled, (field.value as? String ?? "").isEmpty else { continue }
      field.tap()
      field.typeText(value)
    }
  }

  private func launch(arguments: [String] = []) {
    app.launchArguments = useSmileIDSampleSettingsSeed + arguments
    app.launch()
    atATabRoot()
    guard element("sample_session_card").exists || element("sample_session_ended_banner").exists else { return }
    signOut()
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_session_card").waitForNonExistence(timeout: 5))
  }

  /// The scene restores the last test's stack, and a pushed one covers the pill the cleanups need; healed, not assumed.
  private func atATabRoot() {
    guard !element("sample_nav_settings").waitForExistence(timeout: 10) else { return }
    open("products")
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10), "no tab root to clean up from")
  }

  /// The row sits below the fold on the pinned simulator.
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
