import SampleUI
@testable import UseSmileIDSample
import XCTest

/// The minter and decoder have to agree, or a fixture the decoder refuses leaves Simulate silently dead.
final class UseSmileIDSampleFlowTokensTest: XCTestCase {
  func testEveryLiveSpanDecodesOverItsOwnSpanInItsOwnEnvironment() throws {
    for span in UseSmileIDSampleSimulatedSpan.allCases where !span.isEnded {
      for environment in UseSmileIDSampleEnvironment.allCases {
        let session = try XCTUnwrap(decode(span: span, environment: environment), "\(span) \(environment)")
        XCTAssertEqual(session.environment, environment)
        XCTAssertEqual(session.expiresAt.timeIntervalSince(session.issuedAt), span.span)
        XCTAssertFalse(session.hasExpired(at: Self.now))
        XCTAssertEqual(session.progress(at: Self.now), 1, accuracy: 0.001)
      }
    }
  }

  func testTheEndedSpanIsMintedWhollyInThePast() throws {
    let session = try XCTUnwrap(decode(span: .ended))
    XCTAssertTrue(session.hasExpired(at: Self.now))
    XCTAssertLessThan(session.expiresAt, Self.now)
    XCTAssertEqual(session.expiresAt.timeIntervalSince(session.issuedAt), UseSmileIDSampleSimulatedSpan.ended.span)
  }

  func testNoBindingsMeansNoPayloadAndAnUnboundSession() throws {
    let session = try XCTUnwrap(decode(span: .fifteenMinutes))
    XCTAssertEqual(session.bindings, UseSmileIDSampleTokenBindings())
    XCTAssertFalse(session.bindings.bindsRequiredUserDetails)
  }

  /// Bound details carry the four presence flags, the two plaintext claims and the vault reference.
  func testBoundDetailsSatisfyTheUserDetailsRuleAndEveryIdForm() throws {
    let session = try XCTUnwrap(decode(span: .oneHour, bindings: .init(userDetails: true)))
    XCTAssertTrue(session.bindings.bindsRequiredUserDetails)
    XCTAssertEqual(session.bindings.country, "KE")
    XCTAssertEqual(session.bindings.idType, "NATIONAL_ID")
    XCTAssertNotNil(session.bindings.idNumberReference)
    for product in UseSmileIDSampleProduct.allCases {
      XCTAssertTrue(session.bindings.bindsIdDetails(product), product.id)
    }
    XCTAssertNil(session.bindings.consent)
  }

  func testBoundConsentIsCompleteBecauseTheSdkRefusesAPartialOne() throws {
    let session = try XCTUnwrap(decode(span: .eightHours, bindings: .init(consent: true)))
    XCTAssertEqual(session.bindings.consent?.isComplete, true)
    XCTAssertEqual(session.bindings.consent?.grantedAt, "2026-09-02T12:00:00Z")
    XCTAssertFalse(session.bindings.givenNames)
  }

  /// The fixture never carries a name, a number or anything that reads like one.
  func testTheFixtureCarriesNoPlausibleValues() throws {
    let token = UseSmileIDSampleFlowTokens.session(span: .oneHour, bindings: .init(consent: true, userDetails: true), environment: .sandbox, now: Self.now)
    let payload = try XCTUnwrap(token.split(separator: ".").dropFirst().first)
    var base64 = String(payload).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
    let claims = try XCTUnwrap(String(data: XCTUnwrap(Data(base64Encoded: base64)), encoding: .utf8))
    for field in ["given_names", "last_name", "email", "phone_number", "id_number"] {
      XCTAssertTrue(claims.contains("\"\(field)\":\"vault_\(field)\""), field)
    }
  }

  private func decode(
    span: UseSmileIDSampleSimulatedSpan,
    bindings: UseSmileIDSampleSimulatedBindings = .init(),
    environment: UseSmileIDSampleEnvironment = .sandbox
  ) -> UseSmileIDSampleTokenSession? {
    UseSmileIDSampleTokenDecoder.session(
      UseSmileIDSampleFlowTokens.session(span: span, bindings: bindings, environment: environment, now: Self.now)
    )
  }

  /// 2026-09-02T12:00:00Z, so the consent claim's timestamp is a value the test can name.
  private static let now = Date(timeIntervalSince1970: 1788350400)
}
