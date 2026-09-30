import Foundation
@testable import SampleUI
import XCTest

final class UseSmileIDSampleSessionAwareCatalogueSourceTest: XCTestCase {
  private func source() throws -> (UseSmileIDSampleSessionAwareCatalogueSource, UseSmileIDSampleFixtureCatalogueSource) {
    let fixture = try UseSmileIDSampleFixtureCatalogueSource(fixture: UseSmileIDSampleCatalogueFixtures.json)
    return (UseSmileIDSampleSessionAwareCatalogueSource(live: UseSmileIDSampleUnreachableCatalogueSource(), fixture: fixture), fixture)
  }

  private func token(_ header: String) -> String {
    [header, "{}", "not-a-signature"].map { part in
      Data(part.utf8).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }.joined(separator: ".")
  }

  func testASimulatedSessionsUnsignedTokenReadsTheFixture() async throws {
    let (source, fixture) = try source()
    let unsigned = token(#"{"alg":"none","typ":"JWT"}"#)
    let answered = try await source.servicesConfig(environment: .sandbox, token: unsigned, locale: "en-GB")
    let expected = try await fixture.servicesConfig(environment: .sandbox, token: unsigned, locale: "en-GB")
    XCTAssertEqual(answered, expected)
  }

  func testASignedTokenAsksTheServer() async throws {
    let (source, _) = try source()
    do {
      _ = try await source.servicesConfig(environment: .sandbox, token: token(#"{"alg":"HS256","typ":"JWT"}"#), locale: "en-GB")
      XCTFail("a signed token must reach the live source")
    } catch {}
  }
}
