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

    init() throws {
      fixture = try UseSmileIDSampleFixtureCatalogueSource(fixture: UseSmileIDSampleCatalogueFixtures.json)
    }

    func set(failing: Bool = false, hanging: Bool = false) {
      self.failing = failing
      self.hanging = hanging
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
