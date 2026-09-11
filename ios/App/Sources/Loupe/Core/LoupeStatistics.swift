import Foundation

/// What a set of records adds up to, for the summary screen.
struct LoupeStatistics: Equatable {
  var total = 0
  var successes = 0
  var failures = 0
  var requestBytes = 0
  var responseBytes = 0
  var totalDuration: Duration = .zero
  var fastest: Duration?
  var slowest: Duration?

  /// A response counts as a success on a 2xx; a transport error and any other status are failures.
  init(records: [LoupeRecord] = []) {
    total = records.count
    for record in records {
      if let statusCode = record.statusCode, (200..<300).contains(statusCode) {
        successes += 1
      } else {
        failures += 1
      }
      requestBytes += record.requestBody?.count ?? 0
      responseBytes += record.responseBody?.count ?? 0
      guard let duration = record.duration else { continue }
      totalDuration += duration
      fastest = min(fastest ?? duration, duration)
      slowest = max(slowest ?? duration, duration)
    }
  }

  /// Nil rather than zero with no records, so the screen can say so instead of implying a measure.
  var averageDuration: Duration? {
    guard total > 0, totalDuration != .zero else { return nil }
    return totalDuration / total
  }

  var averageRequestBytes: Int {
    total > 0 ? requestBytes / total : 0
  }

  var averageResponseBytes: Int {
    total > 0 ? responseBytes / total : 0
  }
}
