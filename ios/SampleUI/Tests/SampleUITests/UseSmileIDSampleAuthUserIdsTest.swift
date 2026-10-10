import Foundation
@testable import SampleUI
import XCTest

/// Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed.
final class UseSmileIDSampleAuthUserIdsTest: XCTestCase {
  func testNewestFirstAndOnceEachFromEveryProductThatEnrolsAUser() {
    let jobs = [
      Self.job("user_a", .smartSelfieEnrollment, .clear, at: 1),
      Self.job("user_b", .biometricKyc, .attention, at: 3),
      Self.job("user_c", .documentVerification, .processing, at: 2),
      Self.job("user_a", .enhancedDocumentVerification, .clear, at: 4)
    ]
    XCTAssertEqual(useSmileIDSamplePreviousAuthUserIds(jobs, partnerId: Self.partner, sandbox: true), ["user_a", "user_b", "user_c"])
  }

  func testRefusedFailedAuthenticationAndEnhancedKycRunsOfferNone() {
    let jobs = [
      Self.job("user_blocked", .smartSelfieEnrollment, .blocked, at: 1),
      Self.job("user_error", .biometricKyc, .error, at: 2),
      Self.job("user_auth", .smartSelfieAuth, .clear, at: 3),
      Self.job("user_ekyc", .enhancedKyc, .clear, at: 4),
      Self.job(" ", .smartSelfieEnrollment, .clear, at: 5)
    ]
    XCTAssertEqual(useSmileIDSamplePreviousAuthUserIds(jobs, partnerId: Self.partner, sandbox: true), [])
  }

  func testAnotherPartnersUsersOrThisPartnersInTheOtherEnvironmentAreNotOffered() {
    let jobs = [
      Self.job("user_mine", .smartSelfieEnrollment, .clear, at: 1),
      Self.job("user_theirs", .smartSelfieEnrollment, .clear, at: 2, partnerId: "partner-b"),
      Self.job("user_production", .smartSelfieEnrollment, .clear, at: 3, sandbox: false),
      Self.job("user_fixture", .smartSelfieEnrollment, .clear, at: 4, partnerId: nil)
    ]
    XCTAssertEqual(useSmileIDSamplePreviousAuthUserIds(jobs, partnerId: Self.partner, sandbox: true), ["user_mine"])
    XCTAssertEqual(useSmileIDSamplePreviousAuthUserIds(jobs, partnerId: nil, sandbox: true), [])
  }

  private static let partner = "partner-a"

  private static func job(
    _ userId: String,
    _ product: UseSmileIDSampleProduct,
    _ status: UseSmileIDSampleStatus,
    at seconds: TimeInterval,
    partnerId: String? = partner,
    sandbox: Bool = true
  ) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: "job_\(seconds)",
      userId: userId,
      product: product,
      status: status,
      createdAt: Date(timeIntervalSince1970: seconds),
      message: "",
      httpStatus: 200,
      sandbox: sandbox,
      partnerId: partnerId
    )
  }
}
