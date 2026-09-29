import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

/// Match document on every fixture row of both document products, through the SDK's job-type rules.
@MainActor
final class UseSmileIDSampleMatchDocumentTest: XCTestCase {
  private static let products: [UseSmileIDSampleProduct] = [.documentVerification, .enhancedDocumentVerification]

  func testMatchNeverBuildsAPairTheSdkRefuses() throws {
    let documents = try fixtureDocuments()
    var checked = 0
    for product in Self.products {
      for listed in documents {
        for document in UseSmileIDSampleCatalogueRules.documents(documents, country: listed.country.code, product: product) {
          let details = UseSmileIDSampleIdDetails(country: listed.country, document: document)
          let issues = try validate(snapshot(product, details))
          XCTAssertEqual(issues, [], "\(document.id) on \(product.rawValue)")
          checked += 1
        }
      }
    }
    XCTAssertGreaterThan(checked, 0)
  }

  /// Proves the check above can fail: the Green Book preset, chosen on Enhanced Document Verification.
  func testTheRulesRefuseTheGreenBookOnEnhancedDocumentVerification() throws {
    let details = UseSmileIDSampleIdDetails(
      country: UseSmileIDSampleCountry(code: "ZA", name: "South Africa"),
      document: UseSmileIDSampleDocument(code: "IDENTITY_CARD", name: "Identity Card", hasBack: true, format: 1),
      captureAsOverride: .greenBook
    )
    let issues = try validate(snapshot(.enhancedDocumentVerification, details))
    XCTAssertTrue(issues.contains { $0.contains("Green Book") }, "\(issues)")
  }

  private func validate(_ snapshot: FlowLaunchSnapshot) throws -> [String] {
    let registry = try smileIDML { useSmileIDSampleAnalyzers($0, snapshot.product) }.validate()
    let configuration = useSmileIDSampleConfiguration(snapshot, params: useSmileIDSampleIdParams(snapshot))
    let state = FlowValidator.shared.validate(
      configuration: configuration,
      mlAnalyzerRegistry: registry,
      networkClient: UseSmileIDNetworkClient()
    )
    return state.errors.map(\.useSmileIDSampleReason)
  }

  private func snapshot(_ product: UseSmileIDSampleProduct, _ details: UseSmileIDSampleIdDetails) -> FlowLaunchSnapshot {
    FlowLaunchSnapshot(
      product: product,
      route: .fullscreen,
      userDetails: UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@example.com"),
      idDetails: details,
      partnerId: "p-1",
      partnerName: "Test"
    )
  }

  private func fixtureDocuments() throws -> [UseSmileIDSampleApiCountryDocuments] {
    let fixture = try UseSmileIDSampleSpec.object("catalogue-fixture.json")
    let body = try JSONSerialization.data(withJSONObject: XCTUnwrap(fixture["supported_documents"]))
    return try XCTUnwrap(UseSmileIDSampleCatalogueJson.documents(body))
  }
}
