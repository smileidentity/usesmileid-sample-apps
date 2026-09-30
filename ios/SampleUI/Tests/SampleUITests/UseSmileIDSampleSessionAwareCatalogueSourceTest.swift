import Foundation
@testable import SampleUI
import XCTest

final class UseSmileIDSampleSessionAwareCatalogueSourceTest: XCTestCase {
  private func source() throws -> (UseSmileIDSampleSessionAwareCatalogueSource, UseSmileIDSampleFixtureCatalogueSource) {
    let fixture = try UseSmileIDSampleFixtureCatalogueSource(fixture: UseSmileIDSampleCatalogueFixtures.json)
    return (UseSmileIDSampleSessionAwareCatalogueSource(live: UseSmileIDSampleUnreachableCatalogueSource(), fixture: fixture), fixture)
  }

  func testASimulatedSessionsUnsignedTokenReadsTheFixture() async throws {
    let (source, fixture) = try source()
    let unsigned = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.e30.c2lnbmF0dXJl"
    let answered = try await source.servicesConfig(environment: .sandbox, token: unsigned, locale: "en-GB")
    let expected = try await fixture.servicesConfig(environment: .sandbox, token: unsigned, locale: "en-GB")
    XCTAssertEqual(answered, expected)
  }

  func testASignedTokenAsksTheServer() async throws {
    let (source, _) = try source()
    do {
      _ = try await source.servicesConfig(environment: .sandbox, token: "eyJhbGciOiJIUzI1NiJ9.e30.c2lnbmF0dXJl", locale: "en-GB")
      XCTFail("a signed token must reach the live source")
    } catch {}
  }
}
