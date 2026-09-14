import Foundation

/// The instant and zone every dated render is pinned to, so goldens and store art cannot drift apart.
enum UseSmileIDSampleFixedClock {
  /// 2026-07-16T11:50:12Z, the instant the design's rows are dated from.
  static let now = Date(timeIntervalSince1970: 1784202612)

  static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }
}
