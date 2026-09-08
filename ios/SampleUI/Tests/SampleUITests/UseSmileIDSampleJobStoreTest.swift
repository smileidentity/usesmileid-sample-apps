import Foundation
@testable import SampleUI
import XCTest

/// The store's own semantics over storage held in memory; the file itself is the platform's.
final class UseSmileIDSampleJobStoreTest: XCTestCase {
  func testAFreshStoreIsEmpty() async {
    let jobs = await UseSmileIDSampleJobStore(storage: UseSmileIDSampleJobMemoryStorage()).jobs
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

  func testTheRowsAreReadBackByAStoreOverTheSameStorage() async {
    let storage = UseSmileIDSampleJobMemoryStorage()
    let first = UseSmileIDSampleJobStore(storage: storage)
    await first.add(Self.job(id: "job-1"))

    let second = UseSmileIDSampleJobStore(storage: storage)
    let ids = await second.jobs.map(\.id)
    XCTAssertEqual(ids, ["job-1"])
  }

  func testAnUnknownProductOrStatusIdFallsBackRatherThanFailingToLoad() async {
    let stored = """
    {"version":1,"jobs":[{"id":"job-1","userId":"user-1","productId":"retiredProduct",\
    "statusId":"Retired","createdAtMillis":0,"message":"","sandbox":true}]}
    """
    let store = UseSmileIDSampleJobStore(
      storage: UseSmileIDSampleJobMemoryStorage(data: Data(stored.utf8))
    )
    let job = await store.find("job-1")
    XCTAssertEqual(job?.product, UseSmileIDSampleProduct.allCases[0])
    XCTAssertEqual(job?.status, .processing)
  }

  func testStorageThatCannotBeDecodedReadsAsNoRowsRatherThanCrashing() async {
    let store = UseSmileIDSampleJobStore(
      storage: UseSmileIDSampleJobMemoryStorage(data: Data("not json".utf8))
    )
    let jobs = await store.jobs
    XCTAssertEqual(jobs, [])
  }

  func testTheTokensBoundFieldsAreRecordedAsFlagsOnly() async throws {
    let storage = UseSmileIDSampleJobMemoryStorage()
    let store = UseSmileIDSampleJobStore(storage: storage)
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

    let record = try Self.record("job-1", in: storage)
    XCTAssertEqual(record.boundUserDetails, true)
    XCTAssertEqual(record.boundIdDetails, true)
    XCTAssertEqual(record.boundConsent, true)
    let encoded = try XCTUnwrap(try String(data: XCTUnwrap(storage.read()), encoding: .utf8))
    XCTAssertFalse(encoded.contains("vault-ref"), "a binding's value must never be persisted")
  }

  func testNoTokenLeavesEveryBoundFlagFalse() async throws {
    let storage = UseSmileIDSampleJobMemoryStorage()
    let store = UseSmileIDSampleJobStore(storage: storage)
    await store.add(Self.job(id: "job-1"))

    let record = try Self.record("job-1", in: storage)
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

  private static func store() -> UseSmileIDSampleJobStore {
    UseSmileIDSampleJobStore(storage: UseSmileIDSampleJobMemoryStorage())
  }

  private static func record(
    _ id: String,
    in storage: UseSmileIDSampleJobMemoryStorage
  ) throws -> UseSmileIDSampleJobRecord {
    let data = try XCTUnwrap(storage.read())
    let file = try JSONDecoder().decode(UseSmileIDSampleJobFile.self, from: data)
    return try XCTUnwrap(file.jobs.first { $0.id == id })
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
