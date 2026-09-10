import Foundation
import Observation

/// Every exchange recorded this launch, newest first, with the viewer's filter and search.
@MainActor
@Observable
final class LoupeStore {
  private(set) var records: [LoupeRecord] = []
  var visibleKinds: Set<LoupeBodyKind> = Set(LoupeBodyKind.allCases)
  var searchText = ""

  /// Bodies are held in memory, so the history is bounded rather than the launch's whole traffic.
  let limit: Int

  init(limit: Int = 500) {
    self.limit = limit
  }

  /// The kind filter and the search box applied together, which is what the list draws.
  var visibleRecords: [LoupeRecord] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return records.filter { record in
      guard visibleKinds.contains(record.bodyKind) else { return false }
      guard !query.isEmpty else { return true }
      return record.url?.absoluteString.lowercased().contains(query) ?? false
    }
  }

  func append(_ record: LoupeRecord) {
    records.insert(record, at: 0)
    if records.count > limit {
      records.removeLast(records.count - limit)
    }
  }

  func clear() {
    records.removeAll()
  }

  /// Turns one kind on or off, never leaving the set empty, which reads as broken.
  func toggle(_ kind: LoupeBodyKind) {
    if visibleKinds.contains(kind) {
      guard visibleKinds.count > 1 else { return }
      visibleKinds.remove(kind)
    } else {
      visibleKinds.insert(kind)
    }
  }
}
