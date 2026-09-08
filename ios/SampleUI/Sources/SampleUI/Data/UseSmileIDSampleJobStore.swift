import Foundation

/// Where the rows' bytes live: a file in an app, memory in a test.
public protocol UseSmileIDSampleJobStorage: Sendable {
  func read() -> Data?
  /// The whole list is replaced in one write, never patched.
  func write(_ data: Data)
}

/// The submitted verifications, on disk: the SDK delivers a result once. An `actor`, so a write is
/// atomic without a lock, launched from an unstructured `Task` so it outlives the screen that asked.
public actor UseSmileIDSampleJobStore {
  private let storage: UseSmileIDSampleJobStorage
  private let source: UseSmileIDSampleJobStatusSource

  /// In flight per job id, so an entry refresh and a pull cannot double-request the same row.
  private var inFlight: Set<String> = []

  /// Read on first use, not in `init`: nothing touches the file system on the main thread.
  private var rows: [UseSmileIDSampleJobRecord]?

  /// What the last ``remove(_:)`` took, so undo re-inserts rather than clearing a soft-delete column.
  private var lastRemoved: [UseSmileIDSampleJobRecord] = []

  private var listeners: [UUID: AsyncStream<[UseSmileIDSampleJob]>.Continuation] = [:]

  private let removalContinuation: AsyncStream<Int>.Continuation

  /// Batch sizes, consumed once: the details screen navigates away before it could confirm one.
  public let removals: AsyncStream<Int>

  public init(
    storage: UseSmileIDSampleJobStorage = UseSmileIDSampleJobFileStorage(),
    source: UseSmileIDSampleJobStatusSource
  ) {
    self.storage = storage
    self.source = source
    var continuation: AsyncStream<Int>.Continuation!
    removals = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
    removalContinuation = continuation
  }

  /// The rows, newest first: replayed on subscription and yielded again on every write.
  public func jobStream() -> AsyncStream<[UseSmileIDSampleJob]> {
    let current = jobs
    return AsyncStream { continuation in
      let id = UUID()
      listeners[id] = continuation
      continuation.yield(current)
      continuation.onTermination = { [weak self] _ in
        Task { await self?.forget(id) }
      }
    }
  }

  /// Newest first, which is how the list and its date groups read.
  public var jobs: [UseSmileIDSampleJob] {
    stored().sorted { $0.createdAtMillis > $1.createdAtMillis }.map(\.job)
  }

  public func find(_ jobId: String) -> UseSmileIDSampleJob? {
    stored().first { $0.id == jobId }?.job
  }

  /// A no-op on an id already stored, which is what makes a repeated result delivery harmless.
  public func add(_ job: UseSmileIDSampleJob, bindings: UseSmileIDSampleTokenBindings? = nil) {
    insert([
      UseSmileIDSampleJobRecord(
        job: job,
        boundUserDetails: bindings?.bindsRequiredUserDetails == true,
        boundIdDetails: bindings?.bindsIdDetails(job.product) == true,
        boundConsent: bindings?.consent != nil
      )
    ])
  }

  /// Retains the removed rows for ``undoRemove()``; only the most recent batch stays undoable.
  public func remove(_ ids: Set<String>) {
    var rows = stored()
    let taken = rows.filter { ids.contains($0.id) }
    // A removal that took no rows must not discard an earlier batch that is still undoable.
    guard !taken.isEmpty else { return }
    lastRemoved = taken
    rows.removeAll { ids.contains($0.id) }
    save(rows)
    removalContinuation.yield(taken.count)
  }

  /// Order restores itself: the list is ordered by the rows' own timestamps, not by insertion.
  public func undoRemove() {
    guard !lastRemoved.isEmpty else { return }
    insert(lastRemoved)
    lastRemoved = []
  }

  /// The one write that overwrites. Reports whether a row still existed, so a removal mid-refresh wins.
  public func applyStatus(
    _ jobId: String,
    status: UseSmileIDSampleStatus,
    message: String,
    httpStatus: Int
  ) -> Bool {
    var rows = stored()
    guard let index = rows.firstIndex(where: { $0.id == jobId }) else { return false }
    rows[index].statusId = status.rawValue
    rows[index].message = message
    rows[index].httpStatus = httpStatus
    save(rows)
    return true
  }

  /// The environment and the partner come from the row, never the caller. Nil when one is already in
  /// flight, and throws only on cancellation, so leaving mid-request is not a failure.
  public func refresh(
    _ jobId: String,
    live: UseSmileIDSampleTokenSession?,
    now: Date
  ) async throws -> UseSmileIDSampleStatusRefresh? {
    guard inFlight.insert(jobId).inserted else { return nil }
    // Released even on a cancelled caller, or the row is unrefreshable for the rest of the process.
    defer { inFlight.remove(jobId) }

    guard let row = stored().first(where: { $0.id == jobId }) else {
      return .failed(reason: "The verification is no longer stored")
    }
    guard row.sessionId != nil else { return .noServerJob }
    guard let session = live, !session.hasExpired(at: now) else { return .noSession }
    // The partner, not the session: tokens expire and the same partner holds a newer one.
    guard session.partnerId == row.partnerId else { return .partnerMismatch }

    let outcome: UseSmileIDSampleStatusRefresh
    do {
      // The row's environment, never the toggle: a row outlives the toggle that produced it.
      outcome = try await source.check(jobId: jobId, token: session.token, sandbox: row.sandbox)
    } catch is CancellationError {
      throw CancellationError()
    } catch let error as URLError where error.code == .cancelled {
      throw CancellationError()
    } catch is URLError {
      return .failed(reason: "Could not reach the server")
    } catch {
      // The type, never the message: this text goes on screen and a client error carries the URL.
      return .failed(reason: "Unexpected error: \(type(of: error))")
    }

    guard case .updated(let status, let message, let httpCode) = outcome else { return outcome }
    let written = applyStatus(jobId, status: status, message: message, httpStatus: httpCode)
    return written ? outcome : .failed(reason: "The verification is no longer stored")
  }

  /// Reached only by the `seedJobs` launch argument — see `spec/launch-args.json`. Idempotent.
  public func seedFixtures(now: Date) {
    insert(Self.fixtures(now: now).map { UseSmileIDSampleJobRecord(job: $0) })
  }

  /// Ignores an id already stored, so a repeated delivery cannot overwrite the row it already wrote.
  private func insert(_ records: [UseSmileIDSampleJobRecord]) {
    var rows = stored()
    let known = Set(rows.map(\.id))
    let fresh = records.filter { !known.contains($0.id) }
    guard !fresh.isEmpty else { return }
    rows.append(contentsOf: fresh)
    save(rows)
  }

  private func stored() -> [UseSmileIDSampleJobRecord] {
    if let rows {
      return rows
    }
    let decoded = storage.read().flatMap { try? JSONDecoder().decode(UseSmileIDSampleJobFile.self, from: $0) }
    let rows = decoded?.jobs ?? []
    self.rows = rows
    return rows
  }

  /// The one write path: the file, then everyone reading the list. A failed encode leaves it as it was.
  private func save(_ rows: [UseSmileIDSampleJobRecord]) {
    self.rows = rows
    if let data = try? JSONEncoder().encode(UseSmileIDSampleJobFile(jobs: rows)) {
      storage.write(data)
    }
    let jobs = jobs
    for listener in listeners.values {
      listener.yield(jobs)
    }
  }

  private func forget(_ id: UUID) {
    listeners[id] = nil
  }

  /// The eleven the design's counts describe, offset from a caller-supplied now.
  public static func fixtures(now: Date) -> [UseSmileIDSampleJob] {
    let statuses: [UseSmileIDSampleStatus] = [
      .clear, .processing, .clear, .attention, .blocked, .clear, .clear, .attention, .blocked, .clear, .clear
    ]
    let products = UseSmileIDSampleProduct.allCases
    return statuses.enumerated().map { index, status in
      UseSmileIDSampleJob(
        id: String(format: "job_%02dky31za%02d", index, index * 7 % 100),
        userId: String(format: "user_%02dky31za%02d", index, index * 3 % 100),
        product: products[index % products.count],
        status: status,
        createdAt: now.addingTimeInterval(-Double(index) * hoursApart * secondsPerHour),
        message: message(status),
        httpStatus: status == .processing ? httpAccepted : httpOk
      )
    }
  }

  private static func message(_ status: UseSmileIDSampleStatus) -> String {
    switch status {
    case .clear: "Approved"
    case .attention: "Provisional \u{2014} needs review"
    case .blocked: "Rejected"
    case .processing: "Submitted, awaiting result"
    }
  }

  private static let hoursApart: Double = 5
  private static let secondsPerHour: Double = 3600
  private static let httpOk = 200
  private static let httpAccepted = 202
}

/// One JSON file in Application Support, replaced atomically. No identity in the path.
public struct UseSmileIDSampleJobFileStorage: UseSmileIDSampleJobStorage {
  private let url: URL

  public init(fileName: String = "usesmileid_sample_jobs.json") {
    // Falls back rather than indexing into what the platform returned: this runs at launch.
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory())
    url = directory.appendingPathComponent(fileName)
  }

  public func read() -> Data? {
    try? Data(contentsOf: url)
  }

  public func write(_ data: Data) {
    // Created on demand: unlike Documents, Application Support does not exist on a fresh install.
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try? data.write(to: url, options: .atomic)
  }
}

/// Rows held for one process, for tests and for a host that wants no persistence.
public final class UseSmileIDSampleJobMemoryStorage: UseSmileIDSampleJobStorage, @unchecked Sendable {
  private let lock = NSLock()
  private var data: Data?

  public init(data: Data? = nil) {
    self.data = data
  }

  public func read() -> Data? {
    lock.withLock { data }
  }

  public func write(_ data: Data) {
    lock.withLock { self.data = data }
  }
}
