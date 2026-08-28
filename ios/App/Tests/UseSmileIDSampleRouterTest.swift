import SampleUI
@testable import UseSmileIDSample
import XCTest

/// N1's behaviour: a link lands in the right tab with a usable Back stack, a sheet layers over its
/// owner instead of replacing it, and the whole thing survives a cold start as a decode.
@MainActor
final class UseSmileIDSampleRouterTest: XCTestCase {
  private func open(_ link: String) -> UseSmileIDSampleRouter {
    let router = UseSmileIDSampleRouter()
    switch UseSmileIDSampleLinks.resolve(URL(string: link)!) {
    case .route(let route): router.open(route)
    case .sheet(let sheet, let owner):
      router.open(owner)
      router.sheet = sheet
    case nil: XCTFail("\(link) resolved to nothing")
    }
    return router
  }

  func testATabLinkLandsOnTheTabRootWithAnEmptyStack() {
    let router = open("usesmileid-sample-ios://verifications")
    XCTAssertEqual(router.selectedTab, .verifications)
    XCTAssertEqual(router.path(.verifications), [.verifications])
  }

  /// A detail link builds its parent stack, so Back works after a cold link straight into it.
  func testADetailLinkBuildsItsParentStack() {
    let router = open("usesmileid-sample-ios://verifications/job-123")
    XCTAssertEqual(router.selectedTab, .verifications)
    XCTAssertEqual(router.path(.verifications), [.verifications, .verificationDetails(jobId: "job-123")])
  }

  func testANestedDetailLinkBuildsEveryParent() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    XCTAssertEqual(router.selectedTab, .settings)
    XCTAssertEqual(router.path(.settings), [.settings, .profiles, .profileConfig(profileId: "profile-7")])
  }

  /// R12: the owner is on screen underneath, so the sheet's scrim never covers a void.
  func testASheetLinkOpensItsOwnerAndThenTheSheet() {
    let router = open("usesmileid-sample-ios://profiles/switch")
    XCTAssertEqual(router.sheet, .profileSwitch)
    XCTAssertEqual(router.selectedTab, .products)
    XCTAssertEqual(router.path(.products), [.products])
  }

  func testAPickerSheetLinkOpensTheFormThatOwnsIt() {
    let router = open("usesmileid-sample-ios://flow/biometricKyc/id-details/country")
    XCTAssertEqual(router.sheet, .countryPicker)
    XCTAssertEqual(router.path(.products), [.idDetailsForm(productId: "biometricKyc")])
  }

  /// Popping to a depth truncates the path rather than leaving a stale tail behind it.
  func testDeactivatingALevelPopsToExactlyThatDepth() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    router.isActive(.settings, depth: 1).wrappedValue = false
    XCTAssertEqual(router.path(.settings), [.settings])
  }

  func testEachTabKeepsItsOwnStack() {
    let router = UseSmileIDSampleRouter()
    router.open(.verificationDetails(jobId: "job-1"))
    router.open(.licenses)
    XCTAssertEqual(router.selectedTab, .settings)
    XCTAssertEqual(router.path(.verifications), [.verifications, .verificationDetails(jobId: "job-1")])
    XCTAssertEqual(router.path(.settings), [.settings, .licenses])
  }

  func testRestorationIsADecodeOfTheWholeNavigationState() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    let restored = UseSmileIDSampleRouter()
    restored.restore(from: router.encodedState())
    XCTAssertEqual(restored.selectedTab, router.selectedTab)
    XCTAssertEqual(restored.paths, router.paths)
  }

  /// Unreadable scene storage restores the default rather than throwing into a blank window.
  func testUnreadableRestorationStateFallsBackToTheDefault() {
    let router = UseSmileIDSampleRouter()
    router.restore(from: "not json")
    XCTAssertEqual(router.selectedTab, .products)
    XCTAssertTrue(router.paths.isEmpty)
  }

  func testAnUnknownLinkResolvesToNothingRatherThanADefaultScreen() throws {
    XCTAssertNil(try UseSmileIDSampleLinks.resolve(XCTUnwrap(URL(string: "usesmileid-sample-ios://nope"))))
    XCTAssertNil(try UseSmileIDSampleLinks.resolve(XCTUnwrap(URL(string: "usesmileid-sample-android://products"))))
  }
}
