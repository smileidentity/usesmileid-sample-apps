import Foundation
@testable import SampleUI
import XCTest

final class UseSmileIDSampleJobTest: XCTestCase {
  func testAnIdLongerThanTheDesignsColumnIsTruncated() {
    let job = Self.job(id: "0123456789abcdef", userId: "user-0123456789")
    XCTAssertEqual(job.shortId, "01234567\u{2026}")
    XCTAssertEqual(job.shortUserId, "user-012\u{2026}")
  }

  func testAShortIdIsLeftWhole() {
    let job = Self.job(id: "01234567", userId: "abc")
    XCTAssertEqual(job.shortId, "01234567")
    XCTAssertEqual(job.shortUserId, "abc")
  }

  func testTheCreatedAtRowIsUtcIso8601() {
    XCTAssertEqual(
      Self.job(createdAt: Date(timeIntervalSince1970: 1756000000)).createdAtLabel,
      "2025-08-24T01:46:40.000Z"
    )
    XCTAssertEqual(
      Self.job(createdAt: Date(timeIntervalSince1970: 0)).createdAtLabel,
      "1970-01-01T00:00:00.000Z"
    )
  }

  private static func job(
    id: String = "job",
    userId: String = "user",
    createdAt: Date = Date(timeIntervalSince1970: 0)
  ) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: id,
      userId: userId,
      product: .biometricKyc,
      status: .clear,
      createdAt: createdAt,
      message: "Approved",
      httpStatus: 200
    )
  }
}
