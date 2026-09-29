import Foundation
@testable import SampleUI
import XCTest

/// Every case in spec/catalogue-rules.json, through the decoder and rules the app runs on the API's answer.
final class UseSmileIDSampleCatalogueRulesSpecTest: XCTestCase {
  private func section(_ name: String) throws -> [String: Any] {
    try XCTUnwrap(try UseSmileIDSampleSpecFiles.object("catalogue-rules.json")[name] as? [String: Any])
  }

  private func cases(_ name: String) throws -> [[String: Any]] {
    try XCTUnwrap(try section(name)["cases"] as? [[String: Any]])
  }

  private func body(_ key: String, _ value: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: [key: value])
  }

  func testTheAllowedRequiredFieldsAreTheSpecs() throws {
    let allowed = try XCTUnwrap(try section("idTypes")["allowedRequiredFields"] as? [String])
    XCTAssertEqual(Set(allowed), UseSmileIDSampleCatalogueRules.allowedRequiredFields)
  }

  func testIdTypeCases() throws {
    for item in try cases("idTypes") {
      let input = try XCTUnwrap(try UseSmileIDSampleCatalogueJson.idTypes(body("id_types", item["input"] as Any)))
      let actual = UseSmileIDSampleCatalogueRules.idTypes(input, country: item["country"] as? String ?? "")
        .map { [$0.id, $0.type, $0.label] }
      let expected = (item["expected"] as? [[String: String]] ?? []).map { [$0["id"], $0["type"], $0["label"]].compactMap(\.self) }
      XCTAssertEqual(actual, expected, item["name"] as? String ?? "")
    }
  }

  func testDocumentCases() throws {
    for item in try cases("documents") {
      let input = try XCTUnwrap(try UseSmileIDSampleCatalogueJson.documents(body("valid_documents", item["input"] as Any)))
      let actual = UseSmileIDSampleCatalogueRules.documents(input, country: item["country"] as? String ?? "")
      let expected = (item["expected"] as? [[String: Any]] ?? []).map {
        UseSmileIDSampleDocument(
          code: $0["code"] as? String ?? "",
          subType: $0["subType"] as? String,
          name: $0["name"] as? String ?? "",
          hasBack: $0["hasBack"] as? Bool ?? true,
          format: $0["format"] as? Int ?? 0
        )
      }
      XCTAssertEqual(actual, expected, item["name"] as? String ?? "")
      XCTAssertEqual(actual.map(\.id), (item["expected"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String })
    }
  }

  func testCountryCases() async throws {
    for item in try cases("countries") {
      let data: UseSmileIDSampleCatalogueData = if let input = item["input"] as? [String: Any] {
        try UseSmileIDSampleCatalogueData(
          idTypes: UseSmileIDSampleCatalogueJson.idTypes(JSONSerialization.data(withJSONObject: input["supported_id_types"] as Any)) ?? [],
          documents: UseSmileIDSampleCatalogueJson.documents(JSONSerialization.data(withJSONObject: input["supported_documents"] as Any)) ?? []
        )
      } else {
        try await UseSmileIDSampleCatalogueFixtures.data()
      }
      let family: UseSmileIDSampleCatalogueFamily = switch item["family"] as? String {
      case "kyc": .kyc
      case "passport": .passport
      default: .document
      }
      let actual = UseSmileIDSampleCatalogueRules.countries(data, family: family).map { [$0.code, $0.name] }
      let expected = (item["expected"] as? [[String: String]] ?? []).map { [$0["code"] ?? "", $0["name"] ?? ""] }
      XCTAssertEqual(actual, expected, item["name"] as? String ?? "")
    }
  }
}
