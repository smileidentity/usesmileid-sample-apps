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

/// A day of jobs under one header, which is the shape the verifications list renders.
public struct UseSmileIDSampleJobDay: Equatable, Identifiable {
  public let relative: String
  public let absolute: String
  public let jobs: [UseSmileIDSampleJob]

  /// The day itself, which is unique in a grouping and stable across a removal.
  public var id: String {
    absolute
  }

  public init(relative: String, absolute: String, jobs: [UseSmileIDSampleJob]) {
    self.relative = relative
    self.absolute = absolute
    self.jobs = jobs
  }
}

/// Midnight of the day `now` falls in, so a consumer can read the clock coarsely. Idempotent.
public func useSmileIDSampleStartOfDay(_ now: Date, calendar: Calendar = .current) -> Date {
  calendar.startOfDay(for: now)
}

public extension [UseSmileIDSampleJob] {
  /// Groups by calendar day, newest first; the calendar carries the locale and zone a golden pins.
  func groupByDay(_ now: Date, calendar: Calendar = .current) -> [UseSmileIDSampleJobDay] {
    let format = dayFormatter(calendar)
    let today = useSmileIDSampleStartOfDay(now, calendar: calendar)
    // The calendar's own day step, not 86,400 seconds: a DST boundary makes those different days.
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
    var order: [Date] = []
    var byDay: [Date: [UseSmileIDSampleJob]] = [:]
    for job in sorted(by: { $0.createdAt > $1.createdAt }) {
      let day = useSmileIDSampleStartOfDay(job.createdAt, calendar: calendar)
      if byDay[day] == nil {
        order.append(day)
      }
      byDay[day, default: []].append(job)
    }
    return order.map { day in
      let absolute = format.string(from: day).uppercased(with: calendar.locale)
      return UseSmileIDSampleJobDay(
        relative: day == today ? "TODAY" : day == yesterday ? "YESTERDAY" : "",
        absolute: absolute,
        jobs: byDay[day] ?? []
      )
    }
  }

  /// The row's wall-clock time, per job id. One formatter for the whole list.
  func timeLabels(calendar: Calendar = .current) -> [String: String] {
    let format = DateFormatter()
    format.dateFormat = "HH:mm:ss"
    format.locale = calendar.locale
    format.timeZone = calendar.timeZone
    // Last value wins rather than trapping: the caller is a screen and the store's keys are unique.
    return Dictionary(map { ($0.id, format.string(from: $0.createdAt)) }, uniquingKeysWith: { _, latest in latest })
  }
}

private func dayFormatter(_ calendar: Calendar) -> DateFormatter {
  let format = DateFormatter()
  format.dateFormat = "EEE, dd MMM yyyy"
  format.locale = calendar.locale
  format.timeZone = calendar.timeZone
  return format
}
