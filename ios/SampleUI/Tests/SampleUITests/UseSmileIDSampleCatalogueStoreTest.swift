import Foundation
@testable import SampleUI
import XCTest

@MainActor
final class UseSmileIDSampleCatalogueStoreTest: XCTestCase {
  /// Answers from the fixture, counting calls and failing or hanging on request.
  private actor FakeSource: UseSmileIDSampleCatalogueSource {
    let fixture: UseSmileIDSampleFixtureCatalogueSource
    var calls = 0
    var failing = false
    var hanging = false
    var lastEnvironment: UseSmileIDSampleEnvironment?
    var configCalls = 0
    var lastToken: String?
    var refusing: Int?

    init() throws {
      fixture = try UseSmileIDSampleFixtureCatalogueSource(fixture: UseSmileIDSampleCatalogueFixtures.json)
    }

    func set(failing: Bool = false, hanging: Bool = false, refusing: Int? = nil) {
      self.failing = failing
      self.hanging = hanging
      self.refusing = refusing
    }

    func servicesConfig(environment: UseSmileIDSampleEnvironment, token: String, locale: String) async throws -> Data {
      configCalls += 1
      lastToken = token
      if let refusing {
        throw UseSmileIDSampleCatalogueError.http(refusing)
      }
      return try await answer(environment) {
        try await self.fixture.servicesConfig(environment: environment, token: token, locale: locale)
      }
    }

    func supportedIdTypes(environment: UseSmileIDSampleEnvironment) async throws -> Data {
      try await answer(environment) { try await self.fixture.supportedIdTypes(environment: environment) }
    }

    func supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String) async throws -> Data {
      try await answer(environment) { try await self.fixture.supportedDocuments(environment: environment, locale: locale) }
    }

    private func answer(_ environment: UseSmileIDSampleEnvironment, _ body: () async throws -> Data) async throws -> Data {
      calls += 1
      lastEnvironment = environment
      if hanging {
        try await Task.sleep(nanoseconds: 60000000000)
      }
      if failing {
        throw URLError(.notConnectedToInternet)
      }
      return try await body()
    }
  }

  /// Polls rather than sleeping a fixed time, so a slow runner cannot turn a pass into a flake.
  private func eventually(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 2) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition(), Date() < deadline {
      try? await Task.sleep(nanoseconds: 10000000)
    }
  }

  private func session(_ id: String) -> UseSmileIDSampleTokenSession {
    UseSmileIDSampleTokenSession(
      id: id,
      token: "token-\(id)",
      issuedAt: Date(timeIntervalSince1970: 0),
      expiresAt: Date(timeIntervalSince1970: 1),
      bindings: UseSmileIDSampleTokenBindings(),
      environment: .sandbox
    )
  }

  func testEnhancedDocumentVerificationOffersOnlyWhatThePartnerEnabled() async throws {
    let source = try FakeSource()
    let store = UseSmileIDSampleCatalogueStore(source: source)
    store.begin(environment: .sandbox, locale: "en-GB")
    store.ensureEnabled(environment: .sandbox, locale: "en-GB", session: session("a"))
    await eventually(!store.countries(.document, product: .enhancedDocumentVerification).isLoading)
    let token = await source.lastToken
    XCTAssertEqual(token, "token-a")
    guard case .ready(let enabled) = store.countries(.document, product: .enhancedDocumentVerification) else {
      return XCTFail("the partner's countries did not load")
    }
    XCTAssertEqual(enabled.map(\.code), ["KE", "NG"])
    guard case .ready(let all) = store.countries(.document) else { return XCTFail("countries did not load") }
    XCTAssertEqual(all.map(\.code), ["GH", "KE", "NG", "ZA"])
    guard case .ready(let kenya) = store.documents("KE", product: .enhancedDocumentVerification) else {
      return XCTFail("Kenya's documents did not load")
    }
    XCTAssertEqual(kenya.map(\.id), ["IDENTITY_CARD", "PASSPORT"])
  }

  func testThePartnersListIsKeptPerSessionAndARelinkAsksAgain() async throws {
    let source = try FakeSource()
    let store = UseSmileIDSampleCatalogueStore(source: source)
    store.ensureEnabled(environment: .sandbox, locale: "en-GB", session: session("a"))
    await eventually(store.enabled.isReady)
    store.stop()
    store.begin(environment: .sandbox, locale: "en-GB")
    store.ensureEnabled(environment: .sandbox, locale: "en-GB", session: session("a"))
    var calls = await source.configCalls
    XCTAssertEqual(calls, 1, "a new run on the same session must not ask again")
    store.ensureEnabled(environment: .sandbox, locale: "en-GB", session: session("b"))
    await eventually(store.enabled.isReady)
    calls = await source.configCalls
    let token = await source.lastToken
    XCTAssertEqual(calls, 2)
    XCTAssertEqual(token, "token-b")
  }

  func testARefusedTokenNamesTheReasonAndRetryAsksAgain() async throws {
    for status in [401, 403] {
      let source = try FakeSource()
      await source.set(refusing: status)
      let store = UseSmileIDSampleCatalogueStore(source: source)
      store.begin(environment: .production, locale: "en-GB")
      store.ensureEnabled(environment: .production, locale: "en-GB", session: session("a"))
      await eventually(store.countries(.document, product: .enhancedDocumentVerification).isFailed)
      guard case .failed(_, let advice) = store.countries(.document, product: .enhancedDocumentVerification) else {
        return XCTFail("\(status) did not fail")
      }
      XCTAssertEqual(advice, UseSmileIDSampleCatalogueRules.advice(status: status))
      await source.set()
      store.retry()
      await eventually(store.enabled.isReady)
      guard case .ready = store.countries(.document, product: .enhancedDocumentVerification) else {
        return XCTFail("retry did not load")
      }
    }
  }

  func testNoNetworkOnThePartnersListIsTheDefaultError() async throws {
    let source = try FakeSource()
    await source.set(failing: true)
    let store = UseSmileIDSampleCatalogueStore(source: source)
    store.ensureEnabled(environment: .sandbox, locale: "en-GB", session: session("a"))
    await eventually(store.enabled.isFailed)
    guard case .failed(_, let advice) = store.enabled else { return XCTFail("offline did not fail") }
    XCTAssertEqual(advice, UseSmileIDSampleCatalogueRules.defaultAdvice)
  }

  func testAProductTapFetchesBothListsAhead() async throws {
    let source = try FakeSource()
    let store = UseSmileIDSampleCatalogueStore(source: source)
    store.begin(environment: .production, locale: "en-GB")
    await eventually(!store.countries(.kyc).isLoading)
    let calls = await source.calls
    let environment = await source.lastEnvironment
    XCTAssertEqual(calls, 2)
    XCTAssertEqual(environment, .production)
    guard case .ready(let countries) = store.countries(.kyc) else { return XCTFail("countries did not load") }
    XCTAssertEqual(countries.map(\.code), ["GH", "KE", "NG"])
  }

  func testTheFormReusesTheRunsListsAndANewRunAsksAgain() async throws {
    let source = try FakeSource()
    let store = UseSmileIDSampleCatalogueStore(source: source)
    store.begin(environment: .sandbox, locale: "en-GB")
    await eventually(!store.countries(.kyc).isLoading)
    store.ensure(environment: .sandbox, locale: "en-GB")
    var calls = await source.calls
    XCTAssertEqual(calls, 2, "reopening the form must not fetch again")
    store.begin(environment: .sandbox, locale: "en-GB")
    await eventually(!store.countries(.kyc).isLoading)
    calls = await source.calls
    XCTAssertEqual(calls, 4, "the next run asks the server again")
  }

  func testAFailureIsAStateAndRetryAsksAgain() async throws {
    let source = try FakeSource()
    await source.set(failing: true)
    let store = UseSmileIDSampleCatalogueStore(source: source)
    store.begin(environment: .sandbox, locale: "en-GB")
    await eventually(store.countries(.kyc).isFailed)
    XCTAssertTrue(store.countries(.kyc).isFailed)
    await source.set(failing: false)
    store.retry()
    XCTAssertTrue(store.countries(.kyc).isLoading)
    await eventually(!store.countries(.kyc).isLoading)
    guard case .ready = store.countries(.kyc) else { return XCTFail("retry did not load") }
  }

  func testAnAnswerThatNeverComesIsAFailureNeverAnEndlessSkeleton() async throws {
    let source = try FakeSource()
    await source.set(hanging: true)
    let store = UseSmileIDSampleCatalogueStore(source: source, timeoutNanoseconds: 50000000)
    store.begin(environment: .sandbox, locale: "en-GB")
    XCTAssertTrue(store.countries(.document).isLoading)
    await eventually(store.countries(.document).isFailed)
    XCTAssertTrue(store.countries(.document).isFailed)
  }

  func testLeavingCancelsWhatIsInFlight() async throws {
    let source = try FakeSource()
    await source.set(hanging: true)
    let store = UseSmileIDSampleCatalogueStore(source: source, timeoutNanoseconds: 50000000)
    store.begin(environment: .sandbox, locale: "en-GB")
    store.stop()
    try await Task.sleep(nanoseconds: 150000000)
    XCTAssertTrue(store.idTypes.isLoading, "a cancelled fetch must not land after the form is gone")
  }

  func testACountryWithNothingTheFormCanUseIsEmpty() async throws {
    let store = try UseSmileIDSampleCatalogueStore(source: FakeSource())
    store.begin(environment: .sandbox, locale: "en-GB")
    await eventually(!store.countries(.kyc).isLoading)
    guard case .empty = store.idTypes("ET") else { return XCTFail("ET should list nothing") }
    guard case .empty = store.documents("RW") else { return XCTFail("RW should list nothing") }
  }

  func testTheSkeletonWaitsThenStaysAtLeastItsMinimum() async throws {
    let gate = UseSmileIDSampleSkeletonGate(delay: 100000000, minimumShown: 200000000)
    gate.loading(true)
    try await Task.sleep(nanoseconds: 40000000)
    XCTAssertFalse(gate.visible, "a fast answer never flashes a skeleton")
    await eventually(gate.visible)
    XCTAssertTrue(gate.visible)
    gate.loading(false)
    try await Task.sleep(nanoseconds: 60000000)
    XCTAssertTrue(gate.visible, "shown rows never flicker away early")
    await eventually(!gate.visible)
    XCTAssertFalse(gate.visible)
  }

  func testAnAnswerInsideTheDelayShowsNoSkeletonAtAll() async throws {
    let gate = UseSmileIDSampleSkeletonGate(delay: 100000000, minimumShown: 200000000)
    gate.loading(true)
    try await Task.sleep(nanoseconds: 30000000)
    gate.loading(false)
    try await Task.sleep(nanoseconds: 200000000)
    XCTAssertFalse(gate.visible)
  }

  func testTheShippedTimingIsThePlans() {
    XCTAssertEqual(UseSmileIDSampleSkeletonGate.delayNanoseconds, 300000000)
    XCTAssertEqual(UseSmileIDSampleSkeletonGate.minimumShownNanoseconds, 400000000)
  }
}
