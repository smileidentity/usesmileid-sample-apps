// Every state in spec/screens.json has a golden, or an exemption saying why it cannot.

import Foundation
import XCTest

final class UseSmileIDSampleScreenStateGoldenTest: XCTestCase {
  private static let goldens: [String: String] = [
    "products.default": "products_no_session",
    "products.tokenLinked": "products_active_session",
    "products.tokenLinkedLate": "products_session_late",
    "products.tokenExpired": "products_session_ended",
    "profileSwitchSheet.default": "profile_switch",
    "verifications.default": "verifications",
    "verifications.selectMode": "verifications_select",
    "verifications.itemsSelected": "verifications_selected",
    "verifications.afterDelete": "verifications_after_delete",
    "verificationDetails.attention": "verification_details_attention",
    "verificationDetails.clear": "verification_details_clear",
    "verificationDetails.blocked": "verification_details_blocked",
    "verificationDetails.processing": "verification_details_processing",
    "userDetails.empty": "user_details_empty",
    "userDetails.editing": "user_details_editing",
    "userDetails.complete": "user_details_complete",
    "kycIdForm.empty": "kyc_form_empty",
    "kycIdForm.selected": "kyc_form_selected",
    "countryPickerSheet.default": "country_picker",
    "idTypePickerSheet.default": "idtype_picker",
    "settings.default": "settings",
    "settings.altProfile": "settings_alt_profile",
    "settings.newlyCreatedProfile": "settings_new_profile",
    "profiles.default": "profiles",
    "profiles.created": "profiles_created",
    "profileConfig.activeProfile": "profile_config_active",
    "profileConfig.otherProfile": "profile_config_other",
    "profileConfig.newlyCreated": "profile_config_new",
    "newProfileSheet.empty": "new_profile_empty",
    "newProfileSheet.filled": "new_profile_filled",
    "scanToken.default": "scan_token",
    "scanToken.redirected": "scan_token_redirected",
    "licenses.default": "licenses",
    "licenses.empty": "licenses_empty",
    "scenarioDrawer.flowScenarios": "scenario_drawer",
    "scenarioDrawer.themeScenarios": "scenario_drawer_theme"
  ]

  private static let exempt: [String: String] = [
    "consent.notAgreed": "the SDK's own screen: this app decides whether the step runs, never draws it",
    "consent.agreed": "the SDK's own screen: this app decides whether the step runs, never draws it",
    "products.supersededListLayout":
      "a layout the spec keeps only so nobody rebuilds it; there is no implementation to render",
    "verifications.swipeToDelete":
      "the reveal is @GestureState, which rests at zero so there is no half-open row; the device suite drags one",
    "verifications.refreshing":
      "the list's own pull is deferred, and a system-drawn refresh control is not in a static render"
  ]

  func testEverySpecScreenStateHasAGoldenOrADeclaredReason() throws {
    let states = try Self.specStates()
    XCTAssertFalse(states.isEmpty, "extracted no states from spec/screens.json")
    XCTAssertEqual(
      states, Set(Self.goldens.keys).union(Self.exempt.keys),
      "spec/screens.json and the golden inventory have drifted: a state with no golden is never seen"
    )
  }

  func testNoStateIsBothRecordedAndExempt() {
    XCTAssertEqual(Set(Self.goldens.keys).intersection(Self.exempt.keys), [])
  }

  func testEachStateHasItsOwnGolden() {
    // Two states sharing one baseline would leave one of them with no picture of its own.
    XCTAssertEqual(Set(Self.goldens.values).count, Self.goldens.count)
  }

  func testEveryNamedGoldenIsRecordedByATest() throws {
    let recorded = try Self.recordedGoldenNames()
    XCTAssertFalse(recorded.isEmpty, "parsed no golden names from the golden target")
    for (state, name) in Self.goldens.sorted(by: { $0.key < $1.key }) {
      XCTAssertTrue(recorded.contains(name), "\(state) names \(name), which no golden test records")
    }
  }

  private static func specStates() throws -> Set<String> {
    let spec = try UseSmileIDSampleSpecFiles.object("screens.json")
    let screens = try XCTUnwrap(spec["screens"] as? [[String: Any]])
    return Set(screens.flatMap { screen -> [String] in
      let id = screen["id"] as? String ?? ""
      let states = screen["states"] as? [[String: Any]] ?? []
      return states.compactMap { state in
        (state["state"] as? String).map { "\(id).\($0)" }
      }
    })
  }

  private static func recordedGoldenNames() throws -> Set<String> {
    // Every file in the golden target, not one of them: a screen's goldens may be split out later.
    let directory = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("SampleUIGoldenTests")
    let found = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
    let files = (found?.allObjects as? [URL] ?? [])
    let body = try files.filter { $0.pathExtension == "swift" }
      .map { try String(contentsOf: $0, encoding: .utf8) }
      .joined(separator: "\n")
    let pattern = try NSRegularExpression(pattern: #"goldens\("([a-z0-9_]+)""#)
    let range = NSRange(body.startIndex..<body.endIndex, in: body)
    return Set(pattern.matches(in: body, range: range).compactMap {
      Range($0.range(at: 1), in: body).map { String(body[$0]) }
    })
  }
}
