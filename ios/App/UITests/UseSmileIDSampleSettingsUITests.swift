import XCTest

/// The counterpart to `android/maestro/settings.yaml`: the shipped defaults, the mutex driven from the UI, and what a relaunch inherits.
final class UseSmileIDSampleSettingsUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  override func tearDown() {
    app.terminate()
    super.tearDown()
  }

  func testTheSwitchesOpenAtTheirShippedDefaults() {
    launch()
    openSettings()

    assertRows([
      Self.enhancedSmartSelfie: true,
      Self.agentMode: false,
      Self.consentStep: true,
      Self.instructionsStep: true,
      Self.previewStep: true
    ])
  }

  /// Reached by its link, as a flow reaches every sheet; the seed pins Light, and a pick holds for the process.
  func testTheAppearanceSheetChecksTheChoiceAndAPickHolds() {
    launch()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    open("settings/appearance")
    XCTAssertTrue(element(Self.appearanceSheet).waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["sample_appearance_option_light"].isSelected, "the seeded appearance is not checked")
    XCTAssertFalse(app.buttons["sample_appearance_option_system"].isSelected)

    app.buttons["sample_appearance_option_dark"].tap()

    XCTAssertTrue(element(Self.appearanceSheet).waitForNonExistence(timeout: 5))
    XCTAssertTrue(element(Self.appearance).waitForExistence(timeout: 10))
    open("settings/appearance")
    XCTAssertTrue(element(Self.appearanceSheet).waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["sample_appearance_option_dark"].isSelected, "the pick did not hold")
    app.buttons["sample_appearance_option_light"].tap()
  }

  func testOneTapOnAgentModeMovesBothCaptureRowsAndTheirSupportingLines() {
    launch()
    openSettings()
    XCTAssertTrue(app.staticTexts["Face capture uses head-turns"].exists)
    XCTAssertTrue(app.staticTexts["Turns Enhanced SmartSelfie\u{2122} off"].exists)

    switchRow(Self.agentMode).tap()

    assertRows([Self.agentMode: true, Self.enhancedSmartSelfie: false])
    // Each row's supporting line describes the OTHER row's state, so both move on one tap.
    XCTAssertTrue(app.staticTexts["Operator captures for the applicant"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Turns Agent mode off"].exists)

    switchRow(Self.enhancedSmartSelfie).tap()

    assertRows([Self.enhancedSmartSelfie: true, Self.agentMode: false])
    XCTAssertTrue(app.staticTexts["Face capture uses head-turns"].waitForExistence(timeout: 5))
  }

  func testAFlippedSwitchSurvivesARelaunch() {
    launch()
    openSettings()
    switchRow(Self.consentStep).tap()
    assertRows([Self.consentStep: false])

    relaunch(arguments: [])
    openSettings()

    assertRows([Self.consentStep: false])
  }

  func testASeededSwitchIsALaunchOverrideThatPersistsNothing() {
    launch()
    openSettings()
    // Tapped rather than assumed: this is the only way to know what is on disk under this test.
    switchRow(Self.agentMode).tap()
    switchRow(Self.enhancedSmartSelfie).tap()
    assertRows([Self.agentMode: false, Self.enhancedSmartSelfie: true])

    relaunch(arguments: ["-agent_mode", "true", "-enhanced_smart_selfie", "false"])
    openSettings()
    assertRows([Self.agentMode: true, Self.enhancedSmartSelfie: false])

    relaunch(arguments: [])
    openSettings()

    assertRows([Self.agentMode: false, Self.enhancedSmartSelfie: true])
  }

  func testSigningOutClearsTheFormsAndLandsOnProducts() {
    launch()
    fillTheDetailsForm()
    XCTAssertTrue(app.buttons["sample_user_details_continue"].isEnabled)
    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))

    signOut()

    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10), "sign-out did not land on products")
    app.useSmileIDSampleStartProduct("smartSelfieEnrollment")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    XCTAssertFalse(
      app.buttons["sample_user_details_continue"].isEnabled,
      "the typed details survived sign-out"
    )
  }

  func testAFirstRunKeepsItsDetailsAsAProfileTheNextRunFillsFrom() {
    launch()
    signOut()
    app.useSmileIDSampleStartProduct("smartSelfieEnrollment")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["No profile yet"].exists)
    type("sample_user_details_field_organisation", "Kobo")
    type("sample_user_details_field_firstName", "Kwame")
    type("sample_user_details_field_lastName", "Asante")
    type("sample_user_details_field_email", "kwame@uptech.example")
    XCTAssertTrue(app.staticTexts["Save as a new profile"].waitForExistence(timeout: 5))
    app.buttons["sample_user_details_continue"].tap()
    XCTAssertTrue(app.buttons["si_deny_button"].waitForExistence(timeout: 20))

    relaunch(arguments: useSmileIDSampleLaunchSeed)
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    app.useSmileIDSampleStartProduct("smartSelfieEnrollment")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["Kobo"].waitForExistence(timeout: 5), "the stored profile did not name the form")
    XCTAssertEqual(app.textFields["sample_user_details_field_firstName"].value as? String, "Kwame")
    app.buttons["Back"].tap()
    signOut()
  }

  // MARK: - Harness

  private func launch(arguments: [String] = []) {
    app.launchArguments = useSmileIDSampleLaunchSeed + arguments
    app.launch()
  }

  /// The arguments are given whole, so a launch can drop the seed and read what is actually on disk.
  private func relaunch(arguments: [String]) {
    app.terminate()
    app.launchArguments = arguments
    app.launch()
  }

  private func openSettings() {
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
    element("sample_nav_settings").tap()
    XCTAssertTrue(element("sample_settings_screen").waitForExistence(timeout: 10))
  }

  private func fillTheDetailsForm() {
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    app.useSmileIDSampleStartProduct("smartSelfieEnrollment")
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    type("sample_user_details_field_firstName", "Kwame")
    type("sample_user_details_field_lastName", "Asante")
    type("sample_user_details_field_email", "kwame@uptech.example")
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
    let confirm = app.alerts.buttons["sample_sign_out_confirm"].firstMatch
    XCTAssertTrue(confirm.waitForExistence(timeout: 5))
    confirm.tap()
  }

  private func assertRows(_ expected: [String: Bool], file: StaticString = #filePath, line: UInt = #line) {
    for (id, on) in expected {
      let row = switchRow(id)
      XCTAssertTrue(row.waitForExistence(timeout: 10), id, file: file, line: line)
      XCTAssertEqual(row.value as? String, on ? "1" : "0", id, file: file, line: line)
    }
  }

  /// Matched loosely: SwiftUI's `Toggle` puts the identifier on two elements, and an exact query fails as ambiguous.
  private func switchRow(_ id: String) -> XCUIElement {
    app.switches.matching(identifier: id).firstMatch
  }

  /// Replaces rather than appends: a profile kept by an earlier test prefills the form.
  private func type(_ id: String, _ text: String) {
    let field = app.textFields[id]
    XCTAssertTrue(field.waitForExistence(timeout: 5), id)
    field.tap()
    let current = (field.value as? String) ?? ""
    if !current.isEmpty, current != field.placeholderValue {
      field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
    }
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
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
  }

  private static let enhancedSmartSelfie = "sample_setting_enhanced_smart_selfie"
  private static let agentMode = "sample_setting_agent_mode"
  private static let appearance = "sample_setting_appearance"
  private static let appearanceSheet = "sample_appearance_sheet"
  private static let consentStep = "sample_setting_consent_step"
  private static let instructionsStep = "sample_setting_instructions_step"
  private static let previewStep = "sample_setting_preview_step"
}
