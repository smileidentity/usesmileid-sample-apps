import Foundation
@testable import SampleUI
import XCTest

/// Every job status, one table each: its label, its stored id, its chips and its pill's fill.
final class UseSmileIDSampleStatusTest: XCTestCase {
  func testEachStatusReadsInTitleCase() {
    XCTAssertEqual(
      UseSmileIDSampleStatus.allCases.map(\.label),
      ["Clear", "Attention", "Blocked", "Error", "Processing"]
    )
  }

  func testEachStatusIsStoredByItsRawValueAndReadsBackAsItself() {
    let job = UseSmileIDSampleJobStore.fixtures(now: Date(timeIntervalSince1970: 0))[0]
    for status in UseSmileIDSampleStatus.allCases {
      let record = UseSmileIDSampleJobRecord(job: Self.job(job, status: status))
      XCTAssertEqual(record.statusId, status.rawValue)
      XCTAssertEqual(record.job.status, status)
    }
  }

  func testAStoredIdNoStatusHasReadsBackAsProcessing() {
    var record = UseSmileIDSampleJobRecord(job: UseSmileIDSampleJobStore.fixtures(now: Date(timeIntervalSince1970: 0))[0])
    record.statusId = "Quarantined"
    XCTAssertEqual(record.job.status, .processing)
  }

  func testEachStatusIsListedByItsOwnChipAndByAllAndByNoOtherChip() {
    let job = UseSmileIDSampleJobStore.fixtures(now: Date(timeIntervalSince1970: 0))[0]
    let listing = Dictionary(uniqueKeysWithValues: UseSmileIDSampleStatus.allCases.map { status in
      (status, UseSmileIDSampleJobFilter.allCases.filter { $0.matches(Self.job(job, status: status)) })
    })
    XCTAssertEqual(listing, [
      .clear: [.all, .clear],
      .attention: [.all, .attention],
      .blocked: [.all, .blocked],
      .error: [.all, .error],
      .processing: [.all]
    ])
  }

  func testEachStatusPillIsItsRolesSoftFillInBothSchemes() {
    for badge in [UseSmileIDSampleColors.light.badge, UseSmileIDSampleColors.dark.badge] {
      let fills = ["success", "warning", "error", "neutral", "info"].compactMap { smileSoftBadgeFills[$0] }
      XCTAssertEqual(fills.flatMap { [$0.background, $0.text] }, [
        badge.successBackground, badge.successText,
        badge.warningBackground, badge.warningText,
        badge.errorBackground, badge.errorText,
        badge.neutralBackground, badge.neutralText,
        badge.infoBackground, badge.infoText
      ])
    }
  }

  private static func job(_ job: UseSmileIDSampleJob, status: UseSmileIDSampleStatus) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: job.id,
      userId: job.userId,
      product: job.product,
      status: status,
      createdAt: job.createdAt,
      message: job.message,
      httpStatus: job.httpStatus
    )
  }
}
