import XCTest

extension XCUIApplication {
  /// The SDK's consent Deny, under the id every SDK shares or the one builds before it publish.
  var useSmileIDSampleDenyButton: XCUIElement {
    useSmileIDSampleButton("si_consent_deny_button", formerly: "si_deny_button")
  }

  /// The SDK's Exit on a failed run, under the id every SDK shares or the one builds before it publish.
  var useSmileIDSampleExitButton: XCUIElement {
    useSmileIDSampleButton("si_processing_exit_button", formerly: "si_button_exit")
  }

  /// A button by either id, so a test passes on the pinned SDK and on the first build that renames it.
  private func useSmileIDSampleButton(_ id: String, formerly former: String) -> XCUIElement {
    buttons.matching(NSPredicate(format: "identifier IN %@", [id, former])).firstMatch
  }
}
