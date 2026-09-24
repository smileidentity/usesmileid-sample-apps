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
      Self.darkMode: false,
      Self.consentStep: true,
      Self.instructionsStep: true,
      Self.previewStep: true
    ])
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
    element("sample_product_card_smartSelfieEnrollment").tap()
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    XCTAssertFalse(
      app.buttons["sample_user_details_continue"].isEnabled,
      "the typed details survived sign-out"
    )
  }

  // MARK: - Harness

  private func launch(arguments: [String] = []) {
    app.launchArguments = useSmileIDSampleSettingsSeed + arguments
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
    element("sample_product_card_smartSelfieEnrollment").tap()
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
    // It asks first, because it also deletes every profile on the device.
    let confirm = app.alerts.buttons["Sign out"]
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
    // An empty field reports its placeholder as its value.
    if !current.isEmpty, current != field.placeholderValue {
      field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
    }
    field.typeText(text)
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
  }

  private static let enhancedSmartSelfie = "sample_setting_enhanced_smart_selfie"
  private static let agentMode = "sample_setting_agent_mode"
  private static let darkMode = "sample_setting_dark_mode"
  private static let consentStep = "sample_setting_consent_step"
  private static let instructionsStep = "sample_setting_instructions_step"
  private static let previewStep = "sample_setting_preview_step"
}
