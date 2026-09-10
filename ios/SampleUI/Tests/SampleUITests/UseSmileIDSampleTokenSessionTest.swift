@testable import SampleUI
import XCTest

/// The countdown and ring at every span the Portal mints, which is the only affordable way to check an 8h token's seventh hour.
final class UseSmileIDSampleTokenSessionTest: XCTestCase {
  func testTheRingMeasuresTheTokensOwnSpanNotAFixedFiveMinutes() {
    for span in Self.portalSpans {
      let session = session(span)
      XCTAssertEqual(session.progress(at: Self.now), 1, accuracy: Self.tolerance, "full ring at issue for \(span)")
      XCTAssertEqual(session.progress(at: Self.now + span / 2), 0.5, accuracy: Self.tolerance, "half ring at half of \(span)")
      XCTAssertEqual(session.progress(at: Self.now + span), 0, accuracy: Self.tolerance, "empty ring at the deadline for \(span)")
    }
  }

  func testAnHourInAnEightHourTokenStillHasMostOfItsRing() {
    // The bug this replaces: dividing by five minutes pinned the ring at 1 for 55 minutes, then cliffed.
    XCTAssertEqual(session(8 * .hour).progress(at: Self.now + .hour), 0.875, accuracy: Self.tolerance)
    XCTAssertEqual(session(5 * .minute).progress(at: Self.now), 1, accuracy: Self.tolerance)
  }

  func testProgressIsClampedEitherSideOfTheSpan() {
    let session = session(15 * .minute)
    XCTAssertEqual(session.progress(at: Self.now - .hour), 1, accuracy: Self.tolerance)
    XCTAssertEqual(session.progress(at: Self.now + .hour), 0, accuracy: Self.tolerance)
  }

  func testAFreshCountdownReadsMssUnderAnHourAndHmmssAboveIt() {
    XCTAssertEqual(useSmileIDSampleCountdown(session(15 * .minute).remaining(at: Self.now)), "15:00")
    XCTAssertEqual(useSmileIDSampleCountdown(session(.hour).remaining(at: Self.now)), "1:00:00")
    XCTAssertEqual(useSmileIDSampleCountdown(session(8 * .hour).remaining(at: Self.now)), "8:00:00")
  }

  func testAnEightHourTokenReads75912RatherThanOverflowingMinutes() {
    XCTAssertEqual(useSmileIDSampleCountdown(session(8 * .hour).remaining(at: Self.now + 48)), "7:59:12")
  }

  func testTheCountdownPadsBothMinutesAndSecondsOnceThereIsAnHoursPart() {
    XCTAssertEqual(useSmileIDSampleCountdown(.hour + 9), "1:00:09")
    XCTAssertEqual(useSmileIDSampleCountdown(.hour + 9 * .minute), "1:09:00")
    XCTAssertEqual(useSmileIDSampleCountdown(9), "0:09")
    XCTAssertEqual(useSmileIDSampleCountdown(59 * .minute + 59), "59:59")
    XCTAssertEqual(useSmileIDSampleCountdown(0), "0:00")
  }

  func testTheCountdownFloorsRatherThanRoundingSoItNeverShowsTimeThatHasGone() {
    XCTAssertEqual(useSmileIDSampleCountdown(1.999), "0:01")
  }

  func testAZeroSpanReadsAsSpentRatherThanAsNaN() {
    // Unreachable through the decoder, but this initialiser is public and NaN survives a clamp.
    let degenerate = UseSmileIDSampleTokenSession(
      id: "a1b2c3d4",
      token: "header.payload.signature",
      issuedAt: Self.now,
      expiresAt: Self.now,
      bindings: UseSmileIDSampleTokenBindings(),
      environment: .sandbox
    )
    XCTAssertEqual(degenerate.progress(at: Self.now), 0, accuracy: Self.tolerance)
    XCTAssertFalse(degenerate.progress(at: Self.now).isNaN)
  }

  func testExpiryIsTheDeadlineItselfAndRemainingNeverGoesNegative() {
    let session = session(15 * .minute)
    let deadline = Self.now + 15 * .minute
    XCTAssertFalse(session.hasExpired(at: deadline - 0.001))
    XCTAssertTrue(session.hasExpired(at: deadline), "the deadline is expired, not the millisecond after it")
    XCTAssertEqual(session.remaining(at: deadline + .hour), 0)
  }

  private func session(_ span: TimeInterval) -> UseSmileIDSampleTokenSession {
    UseSmileIDSampleTokenSession(
      id: "a1b2c3d4",
      token: "header.payload.signature",
      issuedAt: Self.now,
      expiresAt: Self.now + span,
      bindings: UseSmileIDSampleTokenBindings(),
      environment: .sandbox
    )
  }

  private static let now = Date(timeIntervalSince1970: 1755500000)
  private static let tolerance = 0.0001
  private static let portalSpans: [TimeInterval] = [15 * .minute, .hour, 8 * .hour]
}

private extension TimeInterval {
  static let minute: TimeInterval = 60
  static let hour: TimeInterval = 3600
}
