import XCTest

/// The list, its select mode and both removal paths, against the rows `seedJobs` puts there.
final class UseSmileIDSampleVerificationsUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    // Rows are the precondition, not the subject; re-seeding is a no-op, so a row an earlier test hid is back.
    app.launchArguments = useSmileIDSampleSettingsSeed + ["-seedJobs", "true"]
    app.launch()
    XCTAssertTrue(element("sample_nav_settings").waitForExistence(timeout: 10))
    element("sample_nav_verifications").tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
  }

  func testTheListCarriesTheSeededRowsAndTheDesignsCounts() {
    XCTAssertTrue(element("sample_job_row_0").waitForExistence(timeout: 10))
    XCTAssertEqual(count("all"), "11")
    XCTAssertEqual(count("clear"), "6")
    XCTAssertEqual(count("attention"), "2")
    XCTAssertEqual(count("blocked"), "2")
    XCTAssertTrue(element("sample_job_row_status").exists, "a row's badge is not addressable")
    XCTAssertFalse(element("sample_verifications_empty").exists)
  }

  /// Only provable at rest: content passing under the bar mid-scroll is correct.
  func testTheLastRowClearsTheFloatingBar() {
    let last = element("sample_job_row_10")
    for _ in 0..<6 where !last.exists || !last.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(last.exists, "the last seeded row never came into view")
    XCTAssertLessThanOrEqual(
      last.frame.maxY,
      element("sample_nav_products").frame.minY,
      "the last row sits under the floating bar, so the content inset is missing"
    )
  }

  func testSelectModeReplacesTheNavBarAndCancellingGivesItBack() {
    element("sample_select_toggle").tap()
    XCTAssertTrue(element("sample_selection_bar").waitForExistence(timeout: 10))
    XCTAssertFalse(element("sample_nav_products").exists, "the nav bar stayed behind the selection bar")
    XCTAssertFalse(element("sample_nav_token").exists)
    XCTAssertEqual(element("sample_selection_count").label, "0 selected")

    element("sample_selection_checkbox_0").tap()
    XCTAssertEqual(element("sample_selection_count").label, "1 selected")

    element("sample_select_toggle").tap()
    XCTAssertTrue(element("sample_selection_bar").waitForNonExistence(timeout: 5))
    XCTAssertTrue(element("sample_nav_products").waitForExistence(timeout: 5))
  }

  func testHidingSelectedRowsConfirmsWithAnUndoAndTheCountDrops() {
    element("sample_select_toggle").tap()
    element("sample_selection_checkbox_0").tap()
    element("sample_selection_remove").tap()

    XCTAssertTrue(element("sample_toast").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["1 verification hidden from App list"].exists)
    XCTAssertEqual(count("all"), "10")
    XCTAssertTrue(element("sample_selection_bar").waitForNonExistence(timeout: 5), "select mode outlived the removal")

    element("sample_toast_undo").tap()
    XCTAssertEqual(count("all"), "11")
  }

  func testSwipingARowHidesIt() {
    let row = element("sample_job_row_0")
    XCTAssertTrue(row.waitForExistence(timeout: 10))
    row.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
      .press(
        forDuration: 0.1,
        thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))
      )

    XCTAssertTrue(element("sample_toast").waitForExistence(timeout: 10))
    XCTAssertEqual(count("all"), "10")
  }

  /// Removing the active filter's last row falls back to All, or the screen is blank under a 0.
  func testEmptyingTheActiveFilterFallsBackToAll() {
    element("sample_filter_chip_blocked").tap()
    XCTAssertEqual(count("blocked"), "2")
    XCTAssertTrue(element("sample_job_row_1").waitForExistence(timeout: 10))
    XCTAssertFalse(element("sample_job_row_2").exists, "the filter did not narrow the list")

    element("sample_select_toggle").tap()
    element("sample_selection_checkbox_0").tap()
    element("sample_selection_checkbox_1").tap()
    element("sample_selection_remove").tap()

    XCTAssertTrue(app.buttons["sample_filter_chip_all"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["sample_filter_chip_all"].isSelected, "the emptied filter stayed active")
    XCTAssertEqual(count("all"), "9")
    XCTAssertEqual(count("blocked"), "0")
    XCTAssertTrue(element("sample_job_row_0").exists)
  }

  func testAFilterWithNoRowsSaysSoWithoutClaimingTheListIsEmpty() {
    element("sample_filter_chip_blocked").tap()
    element("sample_select_toggle").tap()
    element("sample_selection_checkbox_0").tap()
    element("sample_selection_checkbox_1").tap()
    element("sample_selection_remove").tap()
    XCTAssertTrue(element("sample_toast").waitForExistence(timeout: 10))

    element("sample_filter_chip_blocked").tap()
    XCTAssertTrue(element("sample_verifications_empty").waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["Nothing blocked"].exists)
    XCTAssertTrue(app.staticTexts["Other filters still have verifications."].exists)
  }

  /// Separable, in visual order, the title a header and nothing merged — none of which a snapshot can show.
  @MainActor
  func testTheAppBarsControlsAreSeparatelyReachable() throws {
    element("sample_job_row_0").tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))

    // `buttons` and `staticTexts` are trait-backed, so these assert how each control is announced.
    let back = app.buttons["Back"]
    let title = app.staticTexts["Verification details"]
    let delete = app.buttons["Hide verification from the app list"]
    XCTAssertTrue(back.exists, "the back control is not announced as a button")
    XCTAssertTrue(title.exists, "the title is not its own element")
    XCTAssertFalse(
      app.buttons["Verification details"].exists,
      "a title announced as a button offers an action it does not have"
    )
    XCTAssertTrue(delete.exists)

    // A merge adds a wrapper repeating the title's words or a control's id; checked first, it makes every query below ambiguous.
    let any = app.descendants(matching: .any)
    XCTAssertEqual(
      any.matching(NSPredicate(format: "label CONTAINS %@", "Verification details")).count, 1,
      "a container repeats the title's words"
    )
    XCTAssertEqual(any.matching(identifier: "sample_details_delete").count, 1, "a container took the delete control's id")

    // Traversal follows layout, so left to right is the order VoiceOver reads.
    XCTAssertLessThan(back.frame.minX, title.frame.minX, "the title is read before the back control")
    XCTAssertLessThan(title.frame.minX, delete.frame.minX, "the action is read before the title")
    XCTAssertNotEqual(try traits(of: title) & UIAccessibilityTraits.header.rawValue, 0, "the title is not a header")
  }

  /// Opening a verification and coming back used to replay a confirmation already spent.
  func testASpentConfirmationDoesNotComeBackWithYou() {
    element("sample_select_toggle").tap()
    element("sample_selection_checkbox_0").tap()
    element("sample_selection_remove").tap()
    XCTAssertTrue(element("sample_toast").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_toast").waitForNonExistence(timeout: 15), "the window never closed")

    element("sample_job_row_0").tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    // Reached by tapping, not by link: the bar is a property of the destination, so one route cannot cover both.
    XCTAssertFalse(element("sample_nav_products").exists)
    XCTAssertFalse(element("sample_nav_token").exists)

    app.buttons["Back"].tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    XCTAssertFalse(element("sample_toast").exists)
  }

  /// Select mode does not follow a tab change; a link is the only way out of it, being the pill it replaced.
  func testSelectModeEndsWhenTheTabChanges() {
    element("sample_select_toggle").tap()
    XCTAssertTrue(element("sample_selection_bar").waitForExistence(timeout: 10))
    element("sample_selection_checkbox_0").tap()

    open("settings")
    XCTAssertTrue(element("sample_settings_screen").waitForExistence(timeout: 10))
    XCTAssertTrue(element("sample_selection_bar").waitForNonExistence(timeout: 5))
    XCTAssertTrue(element("sample_nav_products").exists, "the pill never came back")

    element("sample_nav_verifications").tap()
    XCTAssertTrue(element("sample_verifications_screen").waitForExistence(timeout: 10))
    XCTAssertFalse(element("sample_selection_bar").exists)
  }

  /// A seeded row carries no session, so the outcome is deterministic and needs no network.
  func testEnteringAProcessingRowRefreshesItAndSaysWhyItCannotSucceed() {
    element("sample_job_row_1").tap()
    XCTAssertTrue(element("sample_verification_details_screen").waitForExistence(timeout: 10))
    // The message, not the container: the toast dismisses itself between two queries.
    XCTAssertTrue(app.staticTexts["Not submitted under a scanned token"].waitForExistence(timeout: 10))
  }

  func testEnteringASettledRowRefreshesNothingUntilItIsPulled() {
    element("sample_job_row_0").tap()
    XCTAssertTrue(element("sample_details_refresh").waitForExistence(timeout: 10))
    XCTAssertFalse(element("sample_toast").waitForExistence(timeout: 3), "a settled row refreshed itself")

    // Retried, not tuned: under a full suite the runner coalesces the drag and no velocity made delivery reliable.
    XCTAssertTrue(
      pullToRefreshUntilItSays("Not submitted under a scanned token"),
      "no pull produced the refresh outcome"
    )
  }

  /// The link launches the app, so the row arrives after the screen — the case where "not loaded yet" read as "no row".
  func testAColdStartLinkIntoASettledRowRefreshesNothing() {
    app.terminate()
    open("verifications/job_00ky31za00")
    XCTAssertTrue(element("sample_details_refresh").waitForExistence(timeout: 15))
    XCTAssertFalse(element("sample_details_empty").exists, "the stored row did not survive the relaunch")
    XCTAssertFalse(element("sample_toast").waitForExistence(timeout: 3), "a settled row refreshed itself")
  }

  /// Pulls until the refresh says `message`, waiting on the message itself, since the toast dismisses between two queries.
  private func pullToRefreshUntilItSays(_ message: String, attempts: Int = 4) -> Bool {
    let refresh = element("sample_details_refresh")
    for _ in 0..<attempts {
      refresh.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        .press(
          forDuration: 0.1,
          thenDragTo: refresh.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)),
          withVelocity: .slow,
          thenHoldForDuration: 0.3
        )
      if app.staticTexts[message].waitForExistence(timeout: 5) {
        return true
      }
    }
    return false
  }

  private func count(_ filter: String) -> String {
    element("sample_filter_count_\(filter)").label
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
  }

  /// Traits live on the private class behind the snapshot; the guard fails loudly if an Xcode drops them.
  @MainActor
  private func traits(of element: XCUIElement) throws -> UInt64 {
    let snapshot = try element.snapshot() as AnyObject
    XCTAssertTrue(snapshot.responds(to: NSSelectorFromString("traits")), "the snapshot carries no traits")
    return try XCTUnwrap((snapshot.value(forKey: "traits") as? NSNumber)?.uint64Value)
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
