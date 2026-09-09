import Foundation
import SwiftData

/// The submitted verifications, in SwiftData: the SDK delivers a result once. An `actor`, so a write
/// is atomic without a lock, launched from an unstructured `Task` so it outlives the screen that
/// asked. Rows are written one at a time, so a row that cannot be read is one row rather than all of
/// them — which is what the JSON document this replaced could not promise.
public actor UseSmileIDSampleJobStore {
  private let open: @Sendable () -> ModelContainer?
  private var opened: ModelContext?
  private let source: UseSmileIDSampleJobStatusSource
  private let legacy: UseSmileIDSampleJobImport?

  /// The pre-SwiftData document is read once, on first use rather than in `init`: nothing touches
  /// the file system on the main thread.
  private var importedLegacy = false

  /// In flight per job id, so an entry refresh and a pull cannot double-request the same row.
  private var inFlight: Set<String> = []

  /// What the last ``remove(_:)`` took, so undo re-inserts rather than clearing a soft-delete column.
  private var lastRemoved: [UseSmileIDSampleJobRecord] = []

  private var listeners: [UUID: AsyncStream<[UseSmileIDSampleJob]>.Continuation] = [:]

  private let removalContinuation: AsyncStream<Int>.Continuation

  /// Batch sizes, consumed once: the details screen navigates away before it could confirm one.
  public let removals: AsyncStream<Int>

  /// `importingLegacyFileAt` is the JSON document a pre-SwiftData version left behind; nil is a
  /// store with no history to inherit, which is every test that is not about the import itself.
  public init(
    container: ModelContainer,
    source: UseSmileIDSampleJobStatusSource,
    importingLegacyFileAt url: URL? = nil
  ) {
    self.init(opening: { container }, source: source, importingLegacyFileAt: url)
  }

  private init(
    opening open: @escaping @Sendable () -> ModelContainer?,
    source: UseSmileIDSampleJobStatusSource,
    importingLegacyFileAt url: URL?
  ) {
    self.open = open
    self.source = source
    legacy = url.map { UseSmileIDSampleJobImport(url: $0) }
    var continuation: AsyncStream<Int>.Continuation!
    removals = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
    removalContinuation = continuation
  }

  /// The app's store, and the rows a previous version left in a JSON document.
  ///
  /// A container that cannot be opened degrades to memory rather than trapping: the list then reads
  /// empty, which the screen says out loud, and the app still runs. Crashing on launch is worse.
  public init(source: UseSmileIDSampleJobStatusSource) {
    // The closure, not the container: opening the store is file I/O and this initialiser runs where
    // the app builds its state, which is the main thread at launch.
    self.init(
      opening: { try? ModelContainer.useSmileIDSampleJobs() },
      source: source,
      importingLegacyFileAt: UseSmileIDSampleJobImport.defaultURL
    )
  }

  /// Opened on first use, on the actor rather than wherever `init` was called.
  private func context() -> ModelContext {
    if let opened {
      return opened
    }
    // Force-tried only for the in-memory fallback, which cannot fail for a schema that compiled.
    let container = open() ?? (try! ModelContainer.useSmileIDSampleJobs(inMemory: true))
    let context = ModelContext(container)
    // Saved explicitly at each write, so a partial batch never reaches disk on its own schedule.
    context.autosaveEnabled = false
    opened = context
    return context
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
    write(inserting: [
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
    let doomed = entities().filter { ids.contains($0.id) }
    // A removal that took no rows must not discard an earlier batch that is still undoable.
    guard !doomed.isEmpty else { return }
    let taken = doomed.map(\.record)
    for entity in doomed {
      context().delete(entity)
    }
    guard commit() else { return }
    lastRemoved = taken
    removalContinuation.yield(taken.count)
  }

  /// Order restores itself: the list is ordered by the rows' own timestamps, not by insertion.
  public func undoRemove() {
    guard !lastRemoved.isEmpty else { return }
    write(inserting: lastRemoved)
    lastRemoved = []
  }

  /// The one write that overwrites. Reports whether a row still existed, so a removal mid-refresh wins.
  public func applyStatus(
    _ jobId: String,
    status: UseSmileIDSampleStatus,
    message: String,
    httpStatus: Int
  ) -> Bool {
    guard let entity = entities().first(where: { $0.id == jobId }) else { return false }
    var record = entity.record
    record.statusId = status.rawValue
    record.message = message
    record.httpStatus = httpStatus
    entity.apply(record)
    return commit()
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
    write(inserting: Self.fixtures(now: now).map { UseSmileIDSampleJobRecord(job: $0) })
  }

  private func stored() -> [UseSmileIDSampleJobRecord] {
    entities().map(\.record)
  }

  /// Every row, newest first left to the caller: SwiftData sorts, but the order is the list's rule.
  private func entities() -> [UseSmileIDSampleJobEntity] {
    importLegacyRowsIfNeeded()
    return (try? context().fetch(FetchDescriptor<UseSmileIDSampleJobEntity>())) ?? []
  }

  /// Once, and only where a document was actually left behind. The insert ignores an id already
  /// stored, so a crash between committing and deleting the file repeats the import harmlessly.
  private func importLegacyRowsIfNeeded() {
    guard !importedLegacy else { return }
    importedLegacy = true
    guard let legacy, let pending = legacy.pending() else { return }
    // Committed before the document goes, so a failure between the two repeats the import.
    guard write(inserting: pending) else { return }
    legacy.done()
  }

  /// The one write path: the rows, then everyone reading the list. A failed commit leaves the store
  /// as it was and tells the caller, because a silent failure here loses a partner's history.
  @discardableResult
  private func commit() -> Bool {
    do {
      try context().save()
    } catch {
      context().rollback()
      return false
    }
    let jobs = jobs
    for listener in listeners.values {
      listener.yield(jobs)
    }
    return true
  }

  /// Inserts the records this store does not already hold, keyed by job id.
  @discardableResult
  private func write(inserting records: [UseSmileIDSampleJobRecord]) -> Bool {
    let known = Set(entities().map(\.id))
    let fresh = records.filter { !known.contains($0.id) }
    guard !fresh.isEmpty else { return true }
    for record in fresh {
      context().insert(UseSmileIDSampleJobEntity(record))
    }
    return commit()
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

// One JSON file in Application Support, replaced atomically. No identity in the path.
