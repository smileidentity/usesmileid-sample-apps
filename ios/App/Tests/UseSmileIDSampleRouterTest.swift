import SampleUI
@testable import UseSmileIDSample
import XCTest

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
    XCTAssertEqual(router.path(.verifications), [])
  }

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

  func testNoLinkPushesACopyOfItsOwnTabRoot() {
    for tab in UseSmileIDSampleTab.allCases {
      let router = UseSmileIDSampleRouter()
      router.open(tab.route)
      XCTAssertFalse(router.path(tab).contains(tab.route), "\(tab) pushed its own root")
    }
  }

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

  func testUnreadableRestorationStateFallsBackToTheDefault() {
    let router = UseSmileIDSampleRouter()
    router.restore(from: "not json")
    XCTAssertEqual(router.selectedTab, .products)
    XCTAssertTrue(router.paths.isEmpty)
  }

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
