import Foundation
import Observation

/// Every exchange recorded this launch, newest first, with the viewer's filter and search.
@MainActor
@Observable
final class LoupeStore {
  private(set) var records: [LoupeRecord] = []
  var searchText = ""

  /// Bodies are held in memory, so the history is bounded rather than the launch's whole traffic.
  let limit: Int

  init(limit: Int = 500) {
    self.limit = limit
  }

  /// What the list draws: the search box applied, and nothing else.
  var visibleRecords: [LoupeRecord] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !query.isEmpty else {
      return records
    }
    return records.filter { $0.url?.absoluteString.lowercased().contains(query) ?? false }
  }

  /// When the current window of traffic started, so an export says what it covers.
  private(set) var recordingSince = Date()

  /// How many requests are still out. A hung call shows here and nowhere else.
  var inFlightCount: Int {
    records.count(where: \.isInFlight)
  }

  var failureCount: Int {
    records.count(where: \.isFailure)
  }

  /// Adds a record, or replaces the one it completes — the protocol reports a request twice.
  func upsert(_ record: LoupeRecord) {
    if let existing = records.firstIndex(where: { $0.id == record.id }) {
      records[existing] = record
      return
    }
    records.insert(record, at: 0)
    if records.count > limit {
      records.removeLast(records.count - limit)
    }
  }

  /// Drops everything and restarts the window, so the next export covers only the repro.
  func clear() {
    records.removeAll()
    recordingSince = Date()
  }
}
