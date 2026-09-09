import Foundation
@testable import SampleUI
import SwiftData
import XCTest

/// The refresh sequence the store owns: what it reads off the row, and what it never asks the caller for.
final class UseSmileIDSampleJobStoreRefreshTest: XCTestCase {
  func testRefreshWithNoLiveSessionReportsNoSession() async throws {
    let source = Self.source()
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    let outcome = try await store.refresh("job-1", live: nil, now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .noSession)
    XCTAssertTrue(source.calls.isEmpty)
  }

  func testRefreshWithAnExpiredSessionReportsNoSession() async throws {
    let source = Self.source()
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    let expired = Self.session(id: "s-1", expiresAt: useSmileIDSampleTestNow.addingTimeInterval(-1))
    let outcome = try await store.refresh("job-1", live: expired, now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .noSession)
    XCTAssertTrue(source.calls.isEmpty)
  }

  func testRefreshAsksTheEnvironmentRecordedOnTheRow() async throws {
    let source = Self.source()
    let store = Self.store(source)
    await store.add(Self.job(id: "job-production", sessionId: "s-1", sandbox: false))
    await store.add(Self.job(id: "job-sandbox", sessionId: "s-1"))

    _ = try await store.refresh("job-production", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(source.calls.last?.sandbox, false)

    _ = try await store.refresh("job-sandbox", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(source.calls.last?.sandbox, true)
  }

  func testRefreshUnderADifferentPartnerReportsPartnerMismatchWithoutCallingTheServer() async throws {
    let source = Self.source()
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "old", partnerId: "partner-a"))

    let outcome = try await store.refresh(
      "job-1",
      live: Self.session(id: "new", partnerId: "partner-b"),
      now: useSmileIDSampleTestNow
    )
    XCTAssertEqual(outcome, .partnerMismatch)
    XCTAssertTrue(source.calls.isEmpty)
  }

  func testANewSessionForTheSamePartnerRefreshesARowTheExpiredOneCreated() async throws {
    let source = Self.source()
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "expired"))

    let outcome = try await store.refresh("job-1", live: Self.session(id: "fresh"), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, Self.updated)
    XCTAssertEqual(source.calls.single?.token, "token-fresh")
  }

  func testRefreshOfARowWithoutASessionReportsNoServerJob() async throws {
    let source = Self.source()
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: nil))

    let outcome = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .noServerJob)
    XCTAssertTrue(source.calls.isEmpty)
  }

  func testARowThisBuildNeverHadReportsItIsNoLongerStored() async throws {
    let store = Self.store(Self.source())
    let outcome = try await store.refresh("job-absent", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .failed(reason: "The verification is no longer stored"))
  }

  func testATransportFailureMapsToTheCouldNotReachFailure() async throws {
    let store = Self.store(UseSmileIDSampleFakeStatusSource { _ in throw URLError(.notConnectedToInternet) })
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    let outcome = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .failed(reason: "Could not reach the server"))
  }

  func testAnUnexpectedErrorIsReportedByItsTypeAlone() async throws {
    struct TokenLeak: Error {
      var localizedDescription: String {
        "https://testapi.smileidentity.com?token=secret"
      }
    }
    let store = Self.store(UseSmileIDSampleFakeStatusSource { _ in throw TokenLeak() })
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    let outcome = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .failed(reason: "Unexpected error: TokenLeak"))
  }

  func testACancellationRethrowsInsteadOfReportingFailure() async {
    let store = Self.store(UseSmileIDSampleFakeStatusSource { _ in throw CancellationError() })
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    do {
      _ = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
      XCTFail("a cancellation must not be reported as an outcome")
    } catch {
      XCTAssertTrue(error is CancellationError)
    }
  }

  /// The only point another caller reaches the actor is the suspension the request is waiting on.
  func testARowRemovedMidRequestReportsTheStoredFailure() async throws {
    let source = UseSmileIDSampleFakeStatusSource { _ in .stillProcessing }
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))
    source.answer { _ in
      await store.remove(["job-1"])
      return .updated(status: .clear, message: "Approved", httpCode: 200)
    }

    let outcome = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, .failed(reason: "The verification is no longer stored"))
    let stored = await store.find("job-1")
    XCTAssertNil(stored, "the removal must win, never be resurrected by the write")
  }

  func testASuccessfulUpdateWritesTheRowBack() async throws {
    let store = Self.store(Self.source())
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    let outcome = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, Self.updated)
    let stored = await store.find("job-1")
    XCTAssertEqual(stored?.status, .clear)
    XCTAssertEqual(stored?.message, "Approved")
    XCTAssertEqual(stored?.httpStatus, 200)
  }

  func testAStatusRefreshForAnUnknownJobChangesNothing() async {
    let store = Self.store(Self.source())
    let written = await store.applyStatus("job-absent", status: .clear, message: "Approved", httpStatus: 200)
    XCTAssertFalse(written)
    let stored = await store.find("job-absent")
    XCTAssertNil(stored)
  }

  func testASecondRefreshWhileOneIsInFlightIsSkipped() async throws {
    let gate = UseSmileIDSampleTestGate()
    let source = UseSmileIDSampleFakeStatusSource { _ in .stillProcessing }
    source.answer { _ in
      await gate.announceArrival()
      await gate.waitUntilOpen()
      return .updated(status: .clear, message: "Approved", httpCode: 200)
    }
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    // Hoisted: the isolation checker cannot reason about a static call inside the task.
    let session = Self.session()
    let first = Task { try await store.refresh("job-1", live: session, now: useSmileIDSampleTestNow) }
    await gate.waitForArrival()
    let second = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertNil(second, "the second request must be skipped, not queued")

    await gate.open()
    let outcome = try await first.value
    XCTAssertEqual(outcome, Self.updated)
    XCTAssertEqual(source.calls.count, 1)
  }

  /// Leaving mid-refresh must not make the row unrefreshable for the rest of the process.
  func testACancelledRefreshReleasesTheInFlightGuard() async throws {
    let gate = UseSmileIDSampleTestGate()
    let source = UseSmileIDSampleFakeStatusSource { _ in .stillProcessing }
    source.answer { _ in
      await gate.announceArrival()
      try await Task.sleep(nanoseconds: 5000000000)
      return .stillProcessing
    }
    let store = Self.store(source)
    await store.add(Self.job(id: "job-1", sessionId: "s-1"))

    let session = Self.session()
    let leaving = Task { try? await store.refresh("job-1", live: session, now: useSmileIDSampleTestNow) }
    await gate.waitForArrival()
    leaving.cancel()
    _ = await leaving.value

    source.answer { _ in .updated(status: .clear, message: "Approved", httpCode: 200) }
    let outcome = try await store.refresh("job-1", live: Self.session(), now: useSmileIDSampleTestNow)
    XCTAssertEqual(outcome, Self.updated, "the guard was never released")
  }

  private static func source() -> UseSmileIDSampleFakeStatusSource {
    UseSmileIDSampleFakeStatusSource { _ in .updated(status: .clear, message: "Approved", httpCode: 200) }
  }

  private static func store(_ source: UseSmileIDSampleJobStatusSource) -> UseSmileIDSampleJobStore {
    UseSmileIDSampleJobStore(container: try! .useSmileIDSampleJobs(inMemory: true), source: source)
  }

  private static let updated = UseSmileIDSampleStatusRefresh.updated(
    status: .clear,
    message: "Approved",
    httpCode: 200
  )

  private static func session(
    id: String = "s-1",
    expiresAt: Date = useSmileIDSampleTestNow.addingTimeInterval(60),
    partnerId: String? = useSmileIDSampleTestPartner
  ) -> UseSmileIDSampleTokenSession {
    UseSmileIDSampleTokenSession(
      id: id,
      token: "token-\(id)",
      issuedAt: useSmileIDSampleTestNow.addingTimeInterval(-60),
      expiresAt: expiresAt,
      bindings: UseSmileIDSampleTokenBindings(),
      partnerId: partnerId,
      environment: .sandbox
    )
  }

  private static func job(
    id: String,
    sessionId: String?,
    sandbox: Bool = true,
    partnerId: String? = useSmileIDSampleTestPartner
  ) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: id,
      userId: "user-\(id)",
      product: .smartSelfieEnrollment,
      status: .processing,
      createdAt: Date(timeIntervalSince1970: 0),
      message: "Submitted",
      httpStatus: 202,
      sandbox: sandbox,
      sessionId: sessionId,
      partnerId: partnerId
    )
  }
}

/// The partner both the session and the row carry, unless a case says otherwise.
private let useSmileIDSampleTestPartner = "partner-a"
/// 2026-07-16T11:50:12Z, the instant every fixture is dated from.
private let useSmileIDSampleTestNow = Date(timeIntervalSince1970: 1784202612)

private extension Array {
  var single: Element? {
    count == 1 ? first : nil
  }
}
