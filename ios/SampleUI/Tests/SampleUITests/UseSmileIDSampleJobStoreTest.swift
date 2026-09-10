import Foundation
@testable import SampleUI
import SwiftData
import XCTest

/// The store's own semantics over a container held in memory; the file itself is the platform's.
final class UseSmileIDSampleJobStoreTest: XCTestCase {
  func testAFreshStoreIsEmpty() async {
    let jobs = await Self.store().jobs
    XCTAssertEqual(jobs, [])
  }

  func testAddingTheSameJobTwiceKeepsOneRow() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1"))
    await store.add(Self.job(id: "job-1"))
    let ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-1"])
  }

  func testANewJobLandsFirst() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1", createdAt: Date(timeIntervalSince1970: 1)))
    await store.add(Self.job(id: "job-2", createdAt: Date(timeIntervalSince1970: 2)))
    let ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-2", "job-1"])
  }

  func testUndoReInsertsWhatTheLastRemovalTook() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1", createdAt: Date(timeIntervalSince1970: 1)))
    await store.add(Self.job(id: "job-2", createdAt: Date(timeIntervalSince1970: 2)))

    await store.remove(["job-1"])
    var ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-2"])

    await store.undoRemove()
    ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-2", "job-1"], "the restored row takes its place by timestamp")
  }

  func testAnEmptyRemovalKeepsThePreviousBatchUndoable() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1"))
    await store.remove(["job-1"])
    await store.remove([])
    await store.undoRemove()
    let ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-1"])
  }

  func testRemovingAnUnknownIdLeavesTheEarlierBatchUndoable() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1"))
    await store.remove(["job-1"])
    await store.remove(["job-absent"])
    await store.undoRemove()
    let ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-1"])
  }

  func testTheEnvironmentAndSessionSurviveARoundTrip() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1", sandbox: false, sessionId: "4d33b7ba", partnerId: "partner-a"))
    let stored = await store.find("job-1")
    XCTAssertEqual(stored?.sandbox, false)
    XCTAssertEqual(stored?.sessionId, "4d33b7ba")
    XCTAssertEqual(stored?.partnerId, "partner-a")
  }

  func testTheRowsAreReadBackByAStoreOverTheSameContainer() async {
    let container = Self.container()
    let first = Self.store(container)
    await first.add(Self.job(id: "job-1"))

    let second = Self.store(container)
    let ids = await second.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-1"])
  }

  func testAnUnknownProductOrStatusIdFallsBackRatherThanFailingToLoad() async throws {
    let stored = """
    {"version":1,"jobs":[{"id":"job-1","userId":"user-1","productId":"retiredProduct",\
    "statusId":"Retired","createdAtMillis":0,"message":"","sandbox":true}]}
    """
    let store = try Self.store(legacy: Self.legacyFile(stored))
    let job = await store.find("job-1")
    XCTAssertEqual(job?.product, UseSmileIDSampleProduct.allCases[0])
    XCTAssertEqual(job?.status, .processing)
  }

  func testALegacyDocumentThatCannotBeDecodedReadsAsNoRowsRatherThanCrashing() async throws {
    let store = try Self.store(legacy: Self.legacyFile("not json"))
    let jobs = await store.jobs
    XCTAssertEqual(jobs, [])
  }

  func testTheTokensBoundFieldsAreRecordedAsFlagsOnly() async throws {
    let container = Self.container()
    let store = Self.store(container)
    let bindings = UseSmileIDSampleTokenBindings(
      givenNames: true,
      lastName: true,
      email: true,
      consent: UseSmileIDSampleTokenConsent(),
      country: "KE",
      idType: "NATIONAL_ID",
      idNumberReference: "vault-ref"
    )
    await store.add(Self.job(id: "job-1", product: .biometricKyc), bindings: bindings)

    let record = try Self.record("job-1", in: container)
    XCTAssertEqual(record.boundUserDetails, true)
    XCTAssertEqual(record.boundIdDetails, true)
    XCTAssertEqual(record.boundConsent, true)
    // The persisted row, not the model in memory: the row is what outlives the process.
    let encoded = try XCTUnwrap(String(data: JSONEncoder().encode(record), encoding: .utf8))
    XCTAssertFalse(encoded.contains("vault-ref"), "a binding's value must never be persisted")
  }

  func testNoTokenLeavesEveryBoundFlagFalse() async throws {
    let container = Self.container()
    let store = Self.store(container)
    await store.add(Self.job(id: "job-1"))

    let record = try Self.record("job-1", in: container)
    XCTAssertEqual([record.boundUserDetails, record.boundIdDetails, record.boundConsent], [false, false, false])
  }

  func testOnlyARemovalThatTookRowsEmitsAConfirmation() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1"))
    await store.add(Self.job(id: "job-2"))

    await store.remove(["job-1", "job-2"])
    await store.undoRemove()
    await store.remove([])
    await store.remove(["job-absent"])
    await store.remove(["job-1"])

    var removals = await store.removals.makeAsyncIterator()
    let batch = await removals.next()
    let next = await removals.next()
    XCTAssertEqual([batch, next], [2, 1])
  }

  func testARemovalMadeBeforeAnyoneListensIsStillDelivered() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1"))
    await store.remove(["job-1"])

    var removals = await store.removals.makeAsyncIterator()
    let batch = await removals.next()
    XCTAssertEqual(batch, 1)
  }

  func testTheStreamReplaysTheRowsOnSubscriptionAndYieldsAgainOnAWrite() async {
    let store = Self.store()
    await store.add(Self.job(id: "job-1"))

    var stream = await store.jobStream().makeAsyncIterator()
    let replayed = await stream.next()
    XCTAssertEqual(replayed?.map(\.id), ["job-1"])

    await store.add(Self.job(id: "job-2", createdAt: Date(timeIntervalSince1970: 2)))
    let yielded = await stream.next()
    XCTAssertEqual(yielded?.map(\.id), ["job-2", "job-1"])
  }

  func testAWriteSurvivesCancellationOfTheTaskThatLaunchedIt() async {
    let store = Self.store()
    let job = Self.job(id: "job-1")
    let write = Task { await store.add(job) }
    write.cancel()
    await write.value

    let ids = await store.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-1"])
  }

  func testSeedingIsIdempotentAndCarriesTheDesignsCounts() async {
    let store = Self.store()
    await store.seedFixtures(now: Self.fixedNow)
    await store.seedFixtures(now: Self.fixedNow.addingTimeInterval(3600))
    let jobs = await store.jobs

    XCTAssertEqual(jobs.count, 11)
    XCTAssertEqual(counts(jobs), [.all: 11, .clear: 6, .attention: 2, .blocked: 2])
    XCTAssertEqual(jobs.first?.createdAt, Self.fixedNow, "re-seeding must not re-date a stored row")
  }

  func testAFixtureCarriesNoSession() {
    let fixtures = UseSmileIDSampleJobStore.fixtures(now: Self.fixedNow)
    XCTAssertTrue(fixtures.allSatisfy { $0.sessionId == nil && $0.partnerId == nil })
    XCTAssertTrue(fixtures.allSatisfy(\.sandbox))
  }

  func testTheFixturesAreFiveHoursApartNewestFirst() {
    let fixtures = UseSmileIDSampleJobStore.fixtures(now: Self.fixedNow)
    let gaps = zip(fixtures, fixtures.dropFirst()).map { $0.createdAt.timeIntervalSince($1.createdAt) }
    XCTAssertEqual(gaps, Array(repeating: 5 * 3600, count: 10))
  }

  func testTheProcessingFixtureIsTheOnlyOneStillAccepted() {
    let fixtures = UseSmileIDSampleJobStore.fixtures(now: Self.fixedNow)
    XCTAssertEqual(fixtures.filter { $0.httpStatus == 202 }.map(\.status), [.processing])
    XCTAssertTrue(fixtures.filter { $0.status != .processing }.allSatisfy { $0.httpStatus == 200 })
  }

  func testAFilterMatchesItsOwnStatusAndAllMatchesEverything() {
    let fixtures = UseSmileIDSampleJobStore.fixtures(now: Self.fixedNow)
    XCTAssertTrue(fixtures.allSatisfy(UseSmileIDSampleJobFilter.all.matches))
    for filter in UseSmileIDSampleJobFilter.allCases where filter != .all {
      XCTAssertTrue(fixtures.filter(filter.matches).allSatisfy { $0.status == filter.status })
    }
  }

  private func counts(_ jobs: [UseSmileIDSampleJob]) -> [UseSmileIDSampleJobFilter: Int] {
    Dictionary(
      uniqueKeysWithValues: UseSmileIDSampleJobFilter.allCases.map { ($0, jobs.filter($0.matches).count) }
    )
  }

  private static let noNetwork = UseSmileIDSampleUnreachableStatusSource()

  private static func container() -> ModelContainer {
    // Force-tried: a schema that failed to open in memory is a broken build, not a test condition.
    try! ModelContainer.useSmileIDSampleJobs(inMemory: true)
  }

  private static func store(
    _ container: ModelContainer? = nil,
    legacy: URL? = nil
  ) -> UseSmileIDSampleJobStore {
    UseSmileIDSampleJobStore(
      container: container ?? Self.container(),
      source: noNetwork,
      importingLegacyFileAt: legacy
    )
  }

  /// A pre-SwiftData document on disk where the import reads it, deleted with the test and by the import.
  private static func legacyFile(_ json: String) throws -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("legacy-\(UUID().uuidString).json")
    try Data(json.utf8).write(to: url)
    return url
  }

  private static func record(
    _ id: String,
    in container: ModelContainer
  ) throws -> UseSmileIDSampleJobRecord {
    let context = ModelContext(container)
    let rows = try context.fetch(FetchDescriptor<UseSmileIDSampleJobEntity>())
    return try XCTUnwrap(rows.first { $0.id == id }).record
  }

  private static func job(
    id: String,
    product: UseSmileIDSampleProduct = .smartSelfieEnrollment,
    createdAt: Date = Date(timeIntervalSince1970: 0),
    sandbox: Bool = true,
    sessionId: String? = nil,
    partnerId: String? = nil
  ) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: id,
      userId: "user-\(id)",
      product: product,
      status: .processing,
      createdAt: createdAt,
      message: "Submitted",
      httpStatus: 202,
      sandbox: sandbox,
      sessionId: sessionId,
      partnerId: partnerId
    )
  }

  private static let fixedNow = Date(timeIntervalSince1970: 1784202612)
}
