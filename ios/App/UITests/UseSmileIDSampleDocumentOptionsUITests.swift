import XCTest

/// The document products' form on the fixture lists, through SDK mount; the simulator has no camera, so it stops there.
final class UseSmileIDSampleDocumentOptionsUITests: XCTestCase {
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

  func testTheDocumentListCaptureAsAndTheCustomSheetReachTheSdk() {
    launch()
    openDocumentForm()

    // The document products ask for a document and how to capture it, never an ID number.
    XCTAssertFalse(element("sample_document_trigger").isEnabled)
    XCTAssertFalse(element("sample_idnumber_input").exists)
    element("sample_country_trigger").tap()
    XCTAssertTrue(element("sample_country_option_ZA").waitForExistence(timeout: 10))
    element("sample_country_option_ZA").tap()

    // The Green Book is its own row after its parent; the API's 'Others', whose code is empty, is not listed.
    element("sample_document_trigger").tap()
    XCTAssertTrue(element("sample_document_option_IDENTITY_CARD").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_document_option_IDENTITY_CARD_green_book").exists)
    XCTAssertFalse(element("sample_document_option_").exists)
    element("sample_document_option_IDENTITY_CARD_green_book").tap()

    // Untouched, Capture as matches the document: the Green Book row, then a passport row.
    XCTAssertTrue(element("sample_capture_as_trigger").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_capture_as_trigger").label.contains("Green Book preset · matches document"))
    element("sample_document_trigger").tap()
    XCTAssertTrue(element("sample_document_option_PASSPORT").waitForExistence(timeout: 10))
    element("sample_document_option_PASSPORT").tap()
    XCTAssertTrue(element("sample_capture_as_trigger").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_capture_as_trigger").label.contains("Passport preset · matches document"))

    // Match document first and selected, then the three overrides.
    element("sample_capture_as_trigger").tap()
    XCTAssertTrue(element("sample_capture_as_sheet").waitForExistence(timeout: 10))
    for option in ["matchDocument", "genericDocument", "greenBook", "passport"] {
      XCTAssertTrue(element("sample_capture_as_option_\(option)").exists, option)
    }
    XCTAssertTrue(element("sample_capture_as_option_matchDocument").isSelected)

    // Generic document opens its own sheet, and what it builds is named on the trigger.
    element("sample_capture_as_option_genericDocument").tap()
    XCTAssertTrue(element("sample_generic_document_sheet").waitForExistence(timeout: 10))
    type("sample_generic_document_name", "Booklet")
    element("sample_generic_document_orientation_portrait").tap()
    element("sample_generic_document_aspect_ratio_booklet").tap()
    element("sample_generic_document_done").tap()
    XCTAssertTrue(element("sample_capture_as_trigger").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_capture_as_trigger").label.contains("Booklet · portrait · front and back · chosen"))

    element("sample_kyc_continue").tap()
    XCTAssertTrue(element("si_consent_screen").waitForExistence(timeout: 20), "the SDK did not mount")
  }

  func testAnUnreachableListIsAStateWithRetry() {
    launch(catalogue: "unreachable")
    openDocumentForm()
    element("sample_country_trigger").tap()
    XCTAssertTrue(element("sample_catalogue_error").waitForExistence(timeout: 10))
    element("sample_catalogue_retry").tap()
    XCTAssertTrue(element("sample_catalogue_error").waitForExistence(timeout: 10), "retrying an unreachable list still fails")
  }

  func testEnhancedDocumentVerificationListsOnlyThePartnersDocuments() {
    launch()
    openDocumentForm(product: "enhancedDocumentVerification")
    element("sample_country_trigger").tap()
    XCTAssertTrue(element("sample_country_option_KE").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_country_option_NG").exists)
    XCTAssertFalse(element("sample_country_option_ZA").exists)
    XCTAssertFalse(element("sample_country_option_GH").exists)
    element("sample_country_option_KE").tap()
    element("sample_document_trigger").tap()
    XCTAssertTrue(element("sample_document_option_IDENTITY_CARD").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_document_option_PASSPORT").exists)
    XCTAssertFalse(element("sample_document_option_ALIEN_CARD").exists)
  }

  func testTheIdNumberIsCheckedAgainstItsType() {
    launch()
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    app.useSmileIDSampleStartProduct("biometricKyc")
    continuePastDetails()
    element("sample_country_trigger").tap()
    XCTAssertTrue(element("sample_country_option_KE").waitForExistence(timeout: 10))
    element("sample_country_option_KE").tap()
    element("sample_idtype_trigger").tap()
    XCTAssertTrue(element("sample_idtype_option_NATIONAL_ID").waitForExistence(timeout: 10))
    element("sample_idtype_option_NATIONAL_ID").tap()
    type("sample_idnumber_input", "AO123")
    XCTAssertTrue(element("sample_idnumber_error").waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["sample_kyc_continue"].isEnabled)
    type("sample_idnumber_input", "12345678")
    XCTAssertTrue(element("sample_idnumber_error").waitForNonExistence(timeout: 5))
    XCTAssertTrue(app.buttons["sample_kyc_continue"].isEnabled)
  }

  // MARK: - Journeys

  private func openDocumentForm(product: String = "documentVerification") {
    XCTAssertTrue(element("sample_products_screen").waitForExistence(timeout: 10))
    app.useSmileIDSampleStartProduct(product)
    continuePastDetails()
    XCTAssertTrue(element("sample_kyc_form_screen").waitForExistence(timeout: 10))
  }

  private func continuePastDetails() {
    XCTAssertTrue(element("sample_user_details_screen").waitForExistence(timeout: 10))
    type("sample_user_details_field_firstName", "Kwame")
    type("sample_user_details_field_lastName", "Asante")
    type("sample_user_details_field_email", "kwame@uptech.example")
    let toggle = app.switches["sample_remember_details_switch"]
    if toggle.waitForExistence(timeout: 3), (toggle.value as? String) == "1" {
      for _ in 0..<3 where !toggle.isHittable {
        app.swipeUp()
      }
      toggle.tap()
    }
    app.buttons["sample_user_details_continue"].tap()
  }

  private func launch(catalogue: String = "fixture") {
    app.launchArguments = useSmileIDSampleSettingsSeed + ["-catalogue", catalogue]
    app.launch()
  }

  /// Replaces rather than appends, so a value already in the field cannot prefix the one typed.
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
}
