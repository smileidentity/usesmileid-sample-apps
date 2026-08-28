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

  /// The tab root is the stack's root, so linking to it leaves an empty stack rather than pushing
  /// a second copy of the screen the stack already draws.
  func testATabLinkLandsOnTheTabRootWithAnEmptyStack() {
    let router = open("usesmileid-sample-ios://verifications")
    XCTAssertEqual(router.selectedTab, .verifications)
    XCTAssertEqual(router.path(.verifications), [])
  }

  /// A detail link pushes onto its tab root, so Back after a cold link lands on the list.
  func testADetailLinkPushesOntoItsTabRoot() {
    let router = open("usesmileid-sample-ios://verifications/job-123")
    XCTAssertEqual(router.selectedTab, .verifications)
    XCTAssertEqual(router.path(.verifications), [.verificationDetails(jobId: "job-123")])
  }

  func testANestedDetailLinkBuildsEveryParent() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    XCTAssertEqual(router.selectedTab, .settings)
    XCTAssertEqual(router.path(.settings), [.profiles, .profileConfig(profileId: "profile-7")])
  }

  /// No route may appear both as a stack entry and as the root the stack already draws.
  func testNoLinkPushesACopyOfItsOwnTabRoot() {
    for tab in UseSmileIDSampleTab.allCases {
      let router = UseSmileIDSampleRouter()
      router.open(tab.route)
      XCTAssertFalse(router.path(tab).contains(tab.route), "\(tab) pushed its own root")
    }
  }

  /// R12: the owner is on screen underneath, so the sheet's scrim never covers a void.
  func testASheetLinkOpensItsOwnerAndThenTheSheet() {
    let router = open("usesmileid-sample-ios://profiles/switch")
    XCTAssertEqual(router.sheet, .profileSwitch)
    XCTAssertEqual(router.selectedTab, .products)
    XCTAssertEqual(router.path(.products), [])
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
    XCTAssertEqual(router.path(.settings), [.profiles])
  }

  func testEachTabKeepsItsOwnStack() {
    let router = UseSmileIDSampleRouter()
    router.open(.verificationDetails(jobId: "job-1"))
    router.open(.licenses)
    XCTAssertEqual(router.selectedTab, .settings)
    XCTAssertEqual(router.path(.verifications), [.verificationDetails(jobId: "job-1")])
    XCTAssertEqual(router.path(.settings), [.licenses])
  }

  /// R9: on a cold start the link and the restore race, and the link must not be discarded.
  func testALinkAlreadyOpenedIsNotOverwrittenByALaterRestore() {
    let stored = UseSmileIDSampleRouter()
    stored.open(.licenses)
    let encoded = stored.encodedState()

    let router = open("usesmileid-sample-ios://verifications/job-123")
    router.restore(from: encoded)
    XCTAssertEqual(router.selectedTab, .verifications)
    XCTAssertEqual(router.path(.verifications), [.verificationDetails(jobId: "job-123")])
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

  /// `URL.path` already percent-decodes, so an argument is decoded exactly once. Decoding it again
  /// would corrupt an id whose own value contains a percent escape.
  func testAPercentEncodedArgumentIsDecodedExactlyOnce() throws {
    XCTAssertEqual(try jobId(fromLink: "usesmileid-sample-ios://verifications/job%20123"), "job 123")
    XCTAssertEqual(try jobId(fromLink: "usesmileid-sample-ios://verifications/job%2520123"), "job%20123")
  }

  private func jobId(fromLink link: String) throws -> String {
    let url = try XCTUnwrap(URL(string: link))
    guard case .route(let route) = UseSmileIDSampleLinks.resolve(url),
          case .verificationDetails(let jobId) = route
    else {
      XCTFail("\(link) did not resolve to a verification detail")
      return ""
    }
    return jobId
  }

  /// A stack persisted against an older route table must not seat a route in the wrong tab.
  func testRestoreDropsAStackWhoseRoutesDoNotBelongToItsTab() throws {
    let router = UseSmileIDSampleRouter()
    let stale = UseSmileIDSampleNavigationState(
      selectedTab: .verifications,
      paths: [.verifications: [.licenses], .settings: [.profiles]]
    )
    let encoded = try String(decoding: JSONEncoder().encode(stale), as: UTF8.self)
    router.restore(from: encoded)
    XCTAssertEqual(router.path(.verifications), [], "a settings route must not sit in the verifications stack")
    XCTAssertEqual(router.path(.settings), [.profiles], "a valid stack survives")
  }

  func testAnUnknownLinkResolvesToNothingRatherThanADefaultScreen() throws {
    XCTAssertNil(try UseSmileIDSampleLinks.resolve(XCTUnwrap(URL(string: "usesmileid-sample-ios://nope"))))
    XCTAssertNil(try UseSmileIDSampleLinks.resolve(XCTUnwrap(URL(string: "usesmileid-sample-android://products"))))
  }
}
