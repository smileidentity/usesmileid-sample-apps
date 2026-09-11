import XCTest

/// The suite that drives the real shell; every later screen asserts its route here rather than adding a harness.
final class UseSmileIDSampleNavigationUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    // Seeded because the suite asserts on the design's three profiles; the notice window is widened because its offer is consumed on dismissal.
    app.launchArguments = useSmileIDSampleSettingsSeed + ["-seedProfiles", "true", "-noticeWindow", "60"]
    app.launch()
    clearAnySession()
  }

  /// The session persists across launches, so a test that linked one and failed would hand it to every test after it.
  private func clearAnySession() {
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

  func testALinkOpensAScreenInAnotherTab() {
    open("verifications")
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
  }

  /// The second assertion is the discriminator: a screen id on a container swallows the child's.
  func testALinkOpensTheVerificationDetailsRoute() {
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_details_empty").waitForExistence(timeout: 10))
  }

  /// Addressed by its label: the back control gives back no `sample_*` id on any platform.
  func testTheDetailsScreenPopsBackToItsTab() {
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_verification_details_screen").waitForNonExistence(timeout: 5))
  }

  /// One level at a time chains where §7's deep link does not, so the push is asserted here too.
  func testTheConsentFormGatesContinueThenPushesTheIdForm() {
    open("flow/biometricKyc/details")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    let continueButton = app.buttons["sample_user_details_continue"]
    XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
    XCTAssertFalse(continueButton.isEnabled)
    type("sample_user_details_field_firstName", "Kwame")
    type("sample_user_details_field_lastName", "Asante")
    XCTAssertFalse(continueButton.isEnabled, "a contact is still outstanding")
    type("sample_user_details_field_email", "kwame@uptech.example")
    XCTAssertTrue(continueButton.isEnabled)
    continueButton.tap()
    XCTAssertTrue(
      element("sample_kyc_form_screen").waitForExistence(timeout: 10),
      "the second push did not arrive"
    )
  }

  /// R12 on a device: the picker is a layer over the form, and choosing a country unlocks ID type.
  func testTheIdFormOpensThePickerAndTheChoiceUnlocksIdType() {
    open("flow/biometricKyc/id-details")
    XCTAssertTrue(element("sample_kyc_form_screen").waitForExistence(timeout: 10))
    let idType = app.buttons["sample_idtype_trigger"]
    XCTAssertTrue(idType.waitForExistence(timeout: 10))
    XCTAssertFalse(idType.isEnabled, "ID type has no list without a country")

    app.buttons["sample_country_trigger"].tap()
    XCTAssertTrue(element("sample_country_sheet").waitForExistence(timeout: 10))
    app.buttons["sample_country_option_KE"].tap()

    XCTAssertTrue(element("sample_country_sheet").waitForNonExistence(timeout: 5))
    XCTAssertTrue(app.buttons["sample_idtype_trigger"].isEnabled)
  }

  /// The search text belongs to one visit: a reopened picker must not still be filtered.
  func testAPickerReopensUnfiltered() {
    open("flow/biometricKyc/id-details")
    XCTAssertTrue(element("sample_kyc_form_screen").waitForExistence(timeout: 10))
    app.buttons["sample_country_trigger"].tap()
    XCTAssertTrue(element("sample_country_sheet").waitForExistence(timeout: 10))
    type("sample_country_search", "Ken")
    XCTAssertTrue(app.buttons["sample_country_option_NG"].waitForNonExistence(timeout: 5))
    app.buttons["sample_country_option_KE"].tap()

    XCTAssertTrue(element("sample_country_sheet").waitForNonExistence(timeout: 5))
    app.buttons["sample_country_trigger"].tap()
    XCTAssertTrue(app.buttons["sample_country_option_NG"].waitForExistence(timeout: 10))
  }

  /// A sheet link resolves to its owner plus a sheet request, so the form is open underneath it.
  func testASheetLinkOpensThePickerOverItsOwner() {
    open("flow/biometricKyc/id-details/country")
    XCTAssertTrue(element("sample_country_sheet").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_kyc_form_screen").exists, "the owner did not open beneath the sheet")
  }

  /// The two-level case, landed one level per appearance; Back proves the first is really beneath the second.
  func testALinkOpensATwoLevelRouteInAnotherTab() {
    open("profiles/p-2")
    XCTAssertTrue(
      element("sample_profile_config_screen").waitForExistence(timeout: 10),
      "the pushed level did not arrive"
    )
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_profiles_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_profile_config_screen").waitForNonExistence(timeout: 5))
  }

  /// From inside its own tab the first push would animate, which is the collision the router avoids.
  func testATwoLevelLinkLandsBothLevelsFromWithinItsTab() {
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_sign_out").waitForExistence(timeout: 10))
    open("profiles/p-2")
    XCTAssertTrue(
      element("sample_profile_config_screen").waitForExistence(timeout: 10),
      "the pushed level did not arrive"
    )
  }

  /// A tab remounts when it comes back, so a stack left two deep has to land both levels again.
  func testSwitchingBackToATabLandsItsWholeStackAgain() {
    open("profiles/p-2")
    XCTAssertTrue(element("sample_profile_config_screen").waitForExistence(timeout: 10))
    open("products")
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
    element("sample_nav_settings").tap()
    XCTAssertTrue(
      element("sample_profile_config_screen").waitForExistence(timeout: 10),
      "the second level did not come back with the tab"
    )
  }

  /// With the list already open only the config lands; with another screen open the link starts from the root.
  func testATwoLevelLinkLandsOverWhateverTheTabIsShowing() {
    open("profiles")
    XCTAssertTrue(element("sample_profiles_screen").waitForExistence(timeout: 10))
    open("profiles/p-2")
    XCTAssertTrue(element("sample_profile_config_screen").waitForExistence(timeout: 10))
    open("settings/licenses")
    XCTAssertTrue(element("sample_profile_config_screen").waitForNonExistence(timeout: 5))
    open("profiles/p-3")
    XCTAssertTrue(element("sample_profile_config_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["PesaLink"].waitForExistence(timeout: 5))
  }

  /// The sheet layers over the list, and a created profile is listed but not active until the offer is taken.
  func testCreatingAProfileListsItAndOffersToMakeItActive() {
    open("profiles")
    XCTAssertTrue(element("sample_profiles_screen").waitForExistence(timeout: 10))
    element("sample_create_profile").tap()
    XCTAssertTrue(element("sample_new_profile_sheet").waitForExistence(timeout: 10))
    let create = app.buttons["sample_new_profile_save"]
    XCTAssertTrue(create.waitForExistence(timeout: 10))
    XCTAssertFalse(create.isEnabled)
    type("sample_new_profile_name", "Acme Fintech")
    type("sample_new_profile_first_name", "Ada")
    XCTAssertFalse(create.isEnabled, "the last name is still outstanding")
    type("sample_new_profile_last_name", "Lovelace")
    XCTAssertTrue(create.isEnabled)
    create.tap()

    XCTAssertTrue(element("sample_new_profile_sheet").waitForNonExistence(timeout: 5))
    XCTAssertTrue(element("sample_profile_row_p-4").waitForExistence(timeout: 10), "the new profile is not listed")
    XCTAssertTrue(app.staticTexts["Ada Lovelace"].exists, "created must not mean active")
    // Waited for on the action, not the notice around it: the notice dismisses on a timer, and the second query is a race.
    let makeActive = element("sample_toast_undo")
    XCTAssertTrue(makeActive.waitForExistence(timeout: 5))
    makeActive.tap()
    XCTAssertTrue(app.staticTexts["Ada Lovelace \u{00B7} active"].waitForExistence(timeout: 5))
    XCTAssertTrue(element("sample_toast").waitForNonExistence(timeout: 5))
  }

  /// The CTA is the one place a profile becomes active from its own page, and is disabled on the one that already is.
  func testTheConfigCtaIsDisabledOnTheActiveProfileAndActivatesAnother() {
    open("profiles")
    XCTAssertTrue(element("sample_profiles_screen").waitForExistence(timeout: 10))
    element("sample_profile_row_p-1").tap()
    XCTAssertTrue(element("sample_profile_config_screen").waitForExistence(timeout: 10))
    let save = app.buttons["sample_profile_config_save"]
    XCTAssertTrue(save.waitForExistence(timeout: 10))
    XCTAssertFalse(save.isEnabled, "the active profile cannot be made active again")
    app.buttons["Back"].tap()

    XCTAssertTrue(element("sample_profile_row_p-2").waitForExistence(timeout: 10))
    element("sample_profile_row_p-2").tap()
    XCTAssertTrue(element("sample_profile_config_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(save.isEnabled)
    save.tap()
    XCTAssertTrue(element("sample_profiles_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["Amina Diallo \u{00B7} active"].waitForExistence(timeout: 5))
  }

  /// The switch sheet's path sits under profiles but its owner is products, which is open beneath it.
  func testTheSwitchSheetLinkOpensOverProductsAndSwitchingRenamesSettings() {
    open("profiles/switch")
    XCTAssertTrue(element("sample_profile_switch_sheet").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_products_screen").exists, "the owner did not open beneath the sheet")
    element("sample_profile_row_p-2").tap()
    XCTAssertTrue(element("sample_profile_switch_sheet").waitForNonExistence(timeout: 5))
    element("sample_nav_settings").tap()
    XCTAssertTrue(app.staticTexts["Kazi Microlending"].waitForExistence(timeout: 10))
  }

  func testTheNewProfileLinkOpensTheSheetOverTheProfilesList() {
    open("profiles/new")
    XCTAssertTrue(element("sample_new_profile_sheet").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_profiles_screen").exists, "the owner did not open beneath the sheet")
  }

  /// The second assertion is the discriminator: the screen id must not swallow the sheet's.
  func testALinkOpensTheScanTokenScreenAndBackReturnsToProducts() {
    open("token/scan")
    XCTAssertTrue(element("sample_scan_token_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_token_simulate").exists, "the sheet's id is not queryable under the screen's")
    XCTAssertTrue(element("sample_token_manual_entry").exists)
    XCTAssertTrue(element("sample_token_paste").exists)
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_scan_token_screen").waitForNonExistence(timeout: 5))
  }

  /// Simulate mints the fixture the decoder reads, the store keeps it and the strip shows it, in one tap.
  func testSimulateLinksASessionAndTheProductsStripCountsItDown() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_card").waitForExistence(timeout: 10), "the linked session did not reach products")
    XCTAssertTrue(element("sample_scan_token_screen").waitForNonExistence(timeout: 5))
    let countdown = element("sample_session_countdown")
    XCTAssertTrue(countdown.waitForExistence(timeout: 5))
    XCTAssertNotNil(countdown.label.range(of: #"^1[45]:[0-5]\d$"#, options: .regularExpression), countdown.label)
    // One clock, ticking: the same element reads a different value within a few seconds.
    let ticked = expectation(for: NSPredicate(format: "label != %@", countdown.label), evaluatedWith: countdown)
    wait(for: [ticked], timeout: 5)
  }

  /// The Expired span reaches the expiry path without waiting: retired on arrival, banner for card, and Scan relinks over it.
  func testAnExpiredSimulatedSpanRetiresToTheBannerAndRelinkingReplacesIt() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    app.buttons["SIMULATED SCAN"].tap()
    XCTAssertTrue(element("sample_token_environment_sandbox").waitForExistence(timeout: 5))
    app.buttons["Expired"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_ended_banner").waitForExistence(timeout: 10), "an expired token was not retired to the banner")
    XCTAssertFalse(element("sample_session_card").exists)

    app.buttons["Scan"].tap()
    XCTAssertTrue(element("sample_scan_token_screen").waitForExistence(timeout: 10))
    // The chosen span survived leaving the screen, so the controls are still open.
    XCTAssertTrue(app.buttons["15m"].waitForExistence(timeout: 5), "the typed state did not survive the screen")
    app.buttons["15m"].tap()
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_card").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_session_ended_banner").waitForNonExistence(timeout: 5))
  }

  /// The store is the Keychain, so a relaunch reads the same session back and the clock resumes from its deadline.
  func testALinkedSessionSurvivesARelaunchAndSignOutClearsIt() {
    open("token/scan")
    XCTAssertTrue(element("sample_token_simulate").waitForExistence(timeout: 10))
    element("sample_token_simulate").tap()
    XCTAssertTrue(element("sample_session_card").waitForExistence(timeout: 10))

    app.terminate()
    app.launch()
    XCTAssertTrue(element("sample_session_card").waitForExistence(timeout: 10), "the session did not survive a relaunch")

    signOut()
    element("sample_nav_products").tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_session_card").waitForNonExistence(timeout: 5))
    XCTAssertFalse(element("sample_session_ended_banner").exists, "sign-out must leave no ended marker")
  }

  func testTheNavPillSwitchesTabs() {
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_sign_out").waitForExistence(timeout: 10))
  }

  /// The leak this shell was restructured to close: a tab that is not showing must not answer.
  func testOnlyTheShowingTabsIdsAreQueryable() {
    // Proven present before it is asserted gone: absence alone passes just as well when the id never existed.
    XCTAssertTrue(element("sample_product_card_smartSelfieEnrollment").waitForExistence(timeout: 10))
    element("sample_nav_verifications").tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    // Waited for, not read once: the outgoing subtree lives for the transition, so an instant read is a race.
    XCTAssertTrue(element("sample_product_card_smartSelfieEnrollment").waitForNonExistence(timeout: 5))
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_sign_out").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_verifications_screen").waitForNonExistence(timeout: 5))
    XCTAssertTrue(element("sample_product_card_smartSelfieEnrollment").waitForNonExistence(timeout: 5))
  }

  /// The link opens the drawer over Settings, its owner, and a row's choice is the card's at once without closing it.
  func testTheScenarioDrawerLinkOpensOverSettingsAndASelectionReachesTheCard() {
    open("debug/scenarios")
    XCTAssertTrue(element("sample_scenario_drawer").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_settings_screen").exists, "the owner did not open beneath the sheet")
    let expired = app.buttons["sample_scenario_item_expiredToken"]
    XCTAssertTrue(expired.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["sample_scenario_item_normal"].isSelected, "normal is the default")
    XCTAssertFalse(expired.isSelected)
    expired.tap()
    XCTAssertTrue(expired.isSelected)
    XCTAssertFalse(app.buttons["sample_scenario_item_normal"].isSelected)
    app.buttons["sample_theme_item_clashingHost"].tap()
    XCTAssertTrue(element("sample_scenario_drawer").exists, "a selection must not close the drawer")

    // The route link replaces the drawer's owner, so the drawer goes with it rather than covering the card.
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_scenario_drawer").waitForNonExistence(timeout: 5), "the drawer outlived its owner")
    XCTAssertTrue(element("sample_result_active_scenario").waitForExistence(timeout: 10))
    XCTAssertEqual(element("sample_result_active_scenario").label, "expiredToken")
    XCTAssertEqual(element("sample_result_active_theme").label, "clashingHost")
  }

  /// The DEBUG row belongs to a debug build, which this suite runs; the release lane proves its absence.
  func testTheDebugSettingsRowOpensTheDrawer() {
    element("sample_nav_settings").tap()
    let row = element("sample_scenario_drawer_button")
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    for _ in 0..<4 where !row.isHittable {
      app.swipeUp()
    }
    row.tap()
    XCTAssertTrue(element("sample_scenario_drawer").waitForExistence(timeout: 10))
    // The platform's own dismissal, the sheet having no control: a drag to the bottom edge, since a flick is too short.
    element("sample_scenario_drawer")
      .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      .press(forDuration: 0.3, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
    XCTAssertTrue(element("sample_scenario_drawer").waitForNonExistence(timeout: 5), "the drag did not dismiss the sheet")
    XCTAssertTrue(element("sample_settings_screen").exists, "the owner did not stay")
  }

  /// Twelve ids inside one container, each queryable, and every value read as text rather than prose.
  func testTheResultCardPublishesEveryFieldAsText() {
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_result_card").waitForExistence(timeout: 10))
    let expected = [
      "sample_result_active_scenario": "normal",
      "sample_result_active_theme": "brandDefault",
      "sample_result_route": "fullscreen",
      "sample_result_environment": "sandbox",
      "sample_result_job_id": "\u{2014}",
      "sample_result_user_id": "\u{2014}",
      "sample_result_job_status": "idle",
      "sample_result_result_count": "0",
      "sample_result_refresh_count": "0",
      "sample_result_last_error": "\u{2014}",
      "sample_result_sdk_version": "\u{2014}"
    ]
    for (id, value) in expected {
      let field = element(id)
      XCTAssertTrue(field.exists, "\(id) is not queryable under the card's id")
      XCTAssertEqual(field.label, value, id)
    }
  }

  /// The toggle lives in the app state, so it holds across a tab switch; a collapsed field is absent from the tree.
  func testCollapsingTheCardSurvivesATabSwitch() {
    open("verifications/job_missing")
    XCTAssertTrue(element("sample_result_active_scenario").waitForExistence(timeout: 10))
    app.buttons["Collapse SDK result"].tap()
    XCTAssertTrue(element("sample_result_active_scenario").waitForNonExistence(timeout: 5))
    XCTAssertTrue(element("sample_result_card").exists, "the container stays while its fields go")

    open("products")
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    open("verifications/job_missing")
    XCTAssertTrue(app.buttons["Expand SDK result"].waitForExistence(timeout: 10), "the toggle reset with the screen")
    XCTAssertFalse(element("sample_result_active_scenario").exists)
    app.buttons["Expand SDK result"].tap()
    XCTAssertTrue(element("sample_result_active_scenario").waitForExistence(timeout: 5))
  }

  func testTheLicensesRouteListsTheNoticesAndARowExpandsToItsText() {
    open("settings/licenses")
    XCTAssertTrue(element("sample_licenses_screen").waitForExistence(timeout: 10))
    XCTAssertFalse(element("sample_licenses_empty").exists, "the generated asset did not ship")
    // A row id is built from a component name, so finding one proves the asset reached the screen.
    let row = element("sample_license_row_lottie_spm")
    XCTAssertTrue(row.waitForExistence(timeout: 10), "no row for a component the app links")
    XCTAssertFalse(element("sample_license_text_lottie_spm").exists, "opened already expanded")
    row.tap()
    XCTAssertTrue(element("sample_license_text_lottie_spm").waitForExistence(timeout: 5))
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_settings_screen").waitForExistence(timeout: 10))
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

  /// `simctl openurl` raises a confirmation that swallows the link; this delivery does not, and takes the prompt if shown.
  private func open(_ path: String) {
    XCUIDevice.shared.system.open(URL(string: "usesmileid-sample-ios://\(path)")!)
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let confirm = springboard.buttons["Open"]
    if confirm.waitForExistence(timeout: 2) {
      confirm.tap()
    }
    // Says which half broke: a second app on the same scheme takes the link, which reads as a routing bug here.
    XCTAssertTrue(
      app.wait(for: .runningForeground, timeout: 10),
      "the link did not reach this app — another installed app may claim the scheme"
    )
  }
}
