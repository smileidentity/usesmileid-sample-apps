import Foundation
@testable import SampleUI
import XCTest

/// The date helpers the list memoizes on; every case pins the calendar, so a runner's zone cannot change one.
final class UseSmileIDSampleJobDatesTest: XCTestCase {
  func testFlooringToTheStartOfTheDayIsIdempotent() {
    let once = useSmileIDSampleStartOfDay(Self.fixedNow, calendar: Self.utc)
    XCTAssertEqual(once, useSmileIDSampleStartOfDay(once, calendar: Self.utc))
  }

  func testEveryInstantInADayFloorsToTheSameMidnight() {
    XCTAssertEqual(
      useSmileIDSampleStartOfDay(Self.fixedNow, calendar: Self.utc),
      useSmileIDSampleStartOfDay(Self.fixedNow.addingTimeInterval(3600), calendar: Self.utc)
    )
  }

  func testTimeLabelsMatchPerJobFormatting() {
    let jobs = [
      Self.job(id: "job-1", createdAt: Date(timeIntervalSince1970: 0)),
      Self.job(id: "job-2", createdAt: Date(timeIntervalSince1970: 3723))
    ]
    XCTAssertEqual(jobs.timeLabels(calendar: Self.utc), ["job-1": "00:00:00", "job-2": "01:02:03"])
  }

  func testTodayAndYesterdayAreNamedAndOlderDaysAreDated() {
    let today = useSmileIDSampleStartOfDay(Self.fixedNow, calendar: Self.utc)
    let jobs = [
      Self.job(id: "today", createdAt: today),
      Self.job(id: "yesterday", createdAt: today.addingTimeInterval(-Self.day)),
      Self.job(id: "older", createdAt: today.addingTimeInterval(-2 * Self.day))
    ]
    XCTAssertEqual(
      jobs.groupByDay(today, calendar: Self.utc).map(\.relative),
      ["TODAY", "YESTERDAY", "TUE, 14 JUL 2026"]
    )
  }

  func testTheAbsoluteHalfIsTheDateEvenForToday() {
    let today = useSmileIDSampleStartOfDay(Self.fixedNow, calendar: Self.utc)
    let days = [Self.job(id: "today", createdAt: today)].groupByDay(today, calendar: Self.utc)
    XCTAssertEqual(days.map(\.absolute), ["THU, 16 JUL 2026"])
  }

  func testRowsAreGroupedNewestDayFirstAndNewestRowFirstWithinADay() {
    let today = useSmileIDSampleStartOfDay(Self.fixedNow, calendar: Self.utc)
    let jobs = [
      Self.job(id: "older-day", createdAt: today.addingTimeInterval(-Self.day)),
      Self.job(id: "earlier", createdAt: today.addingTimeInterval(60)),
      Self.job(id: "later", createdAt: today.addingTimeInterval(120))
    ]
    let days = jobs.groupByDay(today, calendar: Self.utc)
    XCTAssertEqual(days.map { $0.jobs.map(\.id) }, [["later", "earlier"], ["older-day"]])
  }

  func testTheSeededFixturesGroupIntoTheDesignsDays() {
    let days = UseSmileIDSampleJobStore.fixtures(now: Self.fixedNow)
      .groupByDay(Self.fixedNow, calendar: Self.utc)
    XCTAssertEqual(days.map(\.relative), ["TODAY", "YESTERDAY", "TUE, 14 JUL 2026"])
    XCTAssertEqual(days.map(\.jobs.count), [3, 5, 3])
  }

  func testYesterdayIsTheCalendarsDayEvenAcrossADaylightSavingBoundary() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
    // The day after New York's clocks went forward: the day before is 25 hours, so subtracting 86,400s lands inside it.
    let today = useSmileIDSampleStartOfDay(Date(timeIntervalSince1970: 1741579200), calendar: calendar)
    let jobs = [Self.job(id: "yesterday", createdAt: today.addingTimeInterval(-3600))]
    XCTAssertEqual(jobs.groupByDay(today, calendar: calendar).map(\.relative), ["YESTERDAY"])
  }

  private static func job(id: String, createdAt: Date) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: id,
      userId: "user-\(id)",
      product: .smartSelfieEnrollment,
      status: .clear,
      createdAt: createdAt,
      message: "",
      httpStatus: 200
    )
  }

  private static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }

  private static let fixedNow = Date(timeIntervalSince1970: 1784202612)
  private static let day: TimeInterval = 24 * 3600
}
