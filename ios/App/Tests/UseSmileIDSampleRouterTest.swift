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

  func testTearingDownTheTabBeingLeftKeepsItsPath() {
    let router = open("usesmileid-sample-ios://settings/licenses")
    XCTAssertEqual(router.path(.settings), [.licenses])
    router.selectedTab = .products
    // What the outgoing stack's teardown does; it must not read as a pop.
    router.isActive(.settings, depth: 0).wrappedValue = false
    XCTAssertEqual(router.path(.settings), [.licenses])
  }

  func testBackOnTheShowingTabStillPops() {
    let router = open("usesmileid-sample-ios://settings/licenses")
    router.isActive(.settings, depth: 0).wrappedValue = false
    XCTAssertEqual(router.path(.settings), [])
  }

  func testNoLinkPushesACopyOfItsOwnTabRoot() {
    for tab in UseSmileIDSampleTab.allCases {
      let router = UseSmileIDSampleRouter()
      router.open(tab.route)
      XCTAssertFalse(router.path(tab).contains(tab.route), "\(tab) pushed its own root")
    }
  }

  /// A drawer left over the details screen would be a layer over the wrong owner.
  func testOpeningARouteDismissesAPresentedSheet() {
    let router = open("usesmileid-sample-ios://debug/scenarios")
    XCTAssertEqual(router.sheet, .scenarioDrawer)
    router.open(.verificationDetails(jobId: "job-1"))
    XCTAssertNil(router.sheet)
    XCTAssertEqual(router.path(.verifications), [.verificationDetails(jobId: "job-1")])
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

  /// The iOS 15 idiom drops a push made during another's transition, so a link stages its levels.
  func testADeepLinkLandsItsLevelsOnePerAppearance() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    XCTAssertTrue(router.isActive(.settings, depth: 0).wrappedValue)
    XCTAssertFalse(router.isActive(.settings, depth: 1).wrappedValue, "the second level waits for the first to appear")
    router.levelDidAppear(.settings, depth: 1)
    XCTAssertTrue(router.isActive(.settings, depth: 1).wrappedValue)
    // The path is complete, so a further appearance lands nothing.
    router.levelDidAppear(.settings, depth: 2)
    XCTAssertEqual(router.path(.settings), [.profiles, .profileConfig(profileId: "profile-7")])
  }

  func testATapPushLandsAtOnce() {
    let router = open("usesmileid-sample-ios://profiles")
    router.push(.profileConfig(profileId: "p-2"))
    XCTAssertTrue(router.isActive(.settings, depth: 1).wrappedValue)
  }

  /// A push while a linked path is still landing must not land two levels in one update either.
  func testATapPushNeverLandsMoreThanOneLevelAtATime() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    router.push(.licenses)
    XCTAssertTrue(router.isActive(.settings, depth: 1).wrappedValue)
    XCTAssertFalse(router.isActive(.settings, depth: 2).wrappedValue, "the config level had not landed yet")
    router.levelDidAppear(.settings, depth: 2)
    XCTAssertTrue(router.isActive(.settings, depth: 2).wrappedValue)
  }

  /// A link into a level already showing lands from there, not from the root.
  func testADeepLinkReusesTheLevelsAlreadyShowing() {
    let router = open("usesmileid-sample-ios://profiles")
    router.levelDidAppear(.settings, depth: 1)
    router.open(.profileConfig(profileId: "p-2"))
    XCTAssertTrue(router.isActive(.settings, depth: 1).wrappedValue, "profiles was showing, so the config lands at once")
    XCTAssertEqual(router.path(.settings), [.profiles, .profileConfig(profileId: "p-2")])
  }

  /// A level that changes route under a link is not "showing" the new path, so it lands from the root.
  func testADeepLinkOverADifferentLevelStartsAgainFromTheRoot() {
    let router = open("usesmileid-sample-ios://settings/licenses")
    router.levelDidAppear(.settings, depth: 1)
    router.open(.profileConfig(profileId: "p-2"))
    XCTAssertTrue(router.isActive(.settings, depth: 0).wrappedValue)
    XCTAssertFalse(router.isActive(.settings, depth: 1).wrappedValue)
  }

  /// A tab coming back on screen mounts a fresh stack, so its levels have to land again one by one.
  func testSelectingATabLandsItsStackFromTheRootAgain() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    router.levelDidAppear(.settings, depth: 1)
    XCTAssertTrue(router.isActive(.settings, depth: 1).wrappedValue)
    router.selectedTab = .products
    router.selectedTab = .settings
    XCTAssertTrue(router.isActive(.settings, depth: 0).wrappedValue)
    XCTAssertFalse(router.isActive(.settings, depth: 1).wrappedValue)
    XCTAssertEqual(router.path(.settings), [.profiles, .profileConfig(profileId: "profile-7")])
  }

  /// Nothing of an unmounted tab is showing, however much of its path a link shares.
  func testALinkIntoAnotherTabLandsFromTheRootEvenOverAMatchingPath() {
    let router = open("usesmileid-sample-ios://profiles")
    router.levelDidAppear(.settings, depth: 1)
    router.selectedTab = .products
    router.open(.profileConfig(profileId: "p-2"))
    XCTAssertEqual(router.selectedTab, .settings)
    XCTAssertTrue(router.isActive(.settings, depth: 0).wrappedValue)
    XCTAssertFalse(router.isActive(.settings, depth: 1).wrappedValue)
  }

  func testPoppingLowersTheLandedLevelWithThePath() {
    let router = open("usesmileid-sample-ios://profiles/profile-7")
    router.levelDidAppear(.settings, depth: 1)
    router.pop()
    XCTAssertFalse(router.isActive(.settings, depth: 1).wrappedValue)
    XCTAssertTrue(router.isActive(.settings, depth: 0).wrappedValue)
    XCTAssertEqual(router.path(.settings), [.profiles])
  }

  func testRestorationLandsOneLevelFirst() {
    let stored = open("usesmileid-sample-ios://profiles/profile-7")
    let router = UseSmileIDSampleRouter()
    router.restore(from: stored.encodedState())
    XCTAssertEqual(router.paths, stored.paths)
    XCTAssertTrue(router.isActive(.settings, depth: 0).wrappedValue)
    XCTAssertFalse(router.isActive(.settings, depth: 1).wrappedValue)
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
