import Foundation

public extension UseSmileIDSampleJob {
  /// ISO-8601 in UTC, matching the design's row: a machine-readable value, not a display date.
  var createdAtLabel: String {
    utcIsoFormatter.string(from: createdAt)
  }
}

private let utcIsoFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.timeZone = TimeZone(identifier: "UTC")
  return formatter
}()
