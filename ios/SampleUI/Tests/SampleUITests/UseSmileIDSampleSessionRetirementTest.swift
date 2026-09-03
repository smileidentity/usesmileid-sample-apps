@testable import SampleUI
import XCTest

/// The record's invariants, against the same synthetic token the Android twin retires.
final class UseSmileIDSampleSessionRetirementTest: XCTestCase {
  private var store: UseSmileIDSampleStore!

  override func setUp() {
    super.setUp()
    store = UseSmileIDSampleStore(storage: UseSmileIDSampleMemoryStorage())
  }

  func testRetiringDeletesTheTokenAndKeepsOnlyTheHandleAndTheDeadline() {
    store.linkTokenSession(Self.session)
    XCTAssertNotNil(store.session.live, "linking must store the token")
    XCTAssertNil(store.session.ended, "a fresh session is not an ended one")

    store.retireTokenSession(Self.session)

    XCTAssertNil(store.session.live, "the credential must be gone")
    XCTAssertEqual(store.session.ended?.id, Self.handle)
    XCTAssertEqual(store.session.ended?.endedAt, Self.expiresAt)
  }

  func testLinkingAgainClearsTheEndedMarkerSoALiveTokenIsNeverShownAsEnded() {
    store.retireTokenSession(Self.session)
    XCTAssertNotNil(store.session.ended)

    store.linkTokenSession(Self.session)

    XCTAssertNil(store.session.ended, "relinking must retire the marker too")
    XCTAssertNotNil(store.session.live)
  }

  func testRetiringTwiceIsIdempotentBecauseALapseCanBeNoticedMoreThanOnce() {
    store.linkTokenSession(Self.session)
    store.retireTokenSession(Self.session)
    store.retireTokenSession(Self.session)

    XCTAssertNil(store.session.live)
    XCTAssertEqual(store.session.ended?.id, Self.handle)
  }

  func testTheLiveHalfAndTheEndedHalfAlwaysComeFromTheSameWrite() {
    store.linkTokenSession(Self.session)
    var record = store.session
    XCTAssertNotNil(record.live)
    XCTAssertNil(record.ended, "a live token and an ended marker must never both be set")

    store.retireTokenSession(Self.session)
    record = store.session
    XCTAssertNil(record.live)
    XCTAssertNotNil(record.ended, "retiring must leave exactly the marker")
  }

  func testNothingStoredReadsAsNeitherLiveNorEnded() {
    XCTAssertNil(store.session.live)
    XCTAssertNil(store.session.ended)
  }

  func testClearingLeavesNoMarkerBecauseSignOutMustNotSendTheNextRunToTheScanner() {
    store.linkTokenSession(Self.session)
    store.clearTokenSession()
    XCTAssertNil(store.session.live)
    XCTAssertNil(store.session.ended)
  }

  /// The stored token is the whole record: the handle and deadline come back from decoding it, not from copies.
  func testTheLiveSessionIsDecodedFromTheStoredToken() {
    store.linkTokenSession(Self.session)
    XCTAssertEqual(store.session.live?.id, Self.handle)
    XCTAssertEqual(store.session.live?.expiresAt, Self.expiresAt)
    XCTAssertEqual(store.session.live?.environment, .sandbox)
  }

  /// The handle the decoder derives for `token`, which is what retirement must keep.
  private static var session: UseSmileIDSampleTokenSession {
    UseSmileIDSampleTokenSession(
      id: handle,
      token: token,
      issuedAt: expiresAt - 900,
      expiresAt: expiresAt,
      bindings: UseSmileIDSampleTokenBindings(),
      environment: .sandbox
    )
  }

  private static let expiresAt = Date(timeIntervalSince1970: 1760000900)

  /// Synthetic and unsigned: the decoder parses a token, never verifies one.
  private static let token = [
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
    // {"iat":1760000000,"exp":1760000900,"api_url":"https://testapi.smileidentity.com/v3"}
    "eyJpYXQiOjE3NjAwMDAwMDAsImV4cCI6MTc2MDAwMDkwMCwiYXBpX3VybCI6Imh0dHBzOi8vdGVzdGFwaS5zbWlsZWlkZW50aXR5LmNvbS92MyJ9",
    "not-a-signature"
  ].joined(separator: ".")

  private static let handle = UseSmileIDSampleTokenDecoder.session(token)!.id
}
