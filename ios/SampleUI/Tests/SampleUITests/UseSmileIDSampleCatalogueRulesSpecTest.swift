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
      let product = (item["product"] as? String).flatMap(UseSmileIDSampleProduct.init(rawValue:)) ?? .documentVerification
      let actual = UseSmileIDSampleCatalogueRules.documents(input, country: item["country"] as? String ?? "", product: product)
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

  private func enabledInput(
    _ item: [String: Any]
  ) async throws -> ([UseSmileIDSampleApiCountryDocuments], [UseSmileIDSampleApiEnabledCountry]) {
    guard let input = item["input"] as? [String: Any] else {
      return try await (UseSmileIDSampleCatalogueFixtures.data().documents, UseSmileIDSampleCatalogueFixtures.enabled())
    }
    return try (
      XCTUnwrap(UseSmileIDSampleCatalogueJson.documents(JSONSerialization.data(withJSONObject: input["supported_documents"] as Any))),
      XCTUnwrap(UseSmileIDSampleCatalogueJson.enabledCountries(JSONSerialization.data(withJSONObject: input["services_config"] as Any)))
    )
  }

  func testEnabledDocumentCases() async throws {
    for item in try cases("enabledDocuments") {
      let (documents, enabled) = try await enabledInput(item)
      let actual = UseSmileIDSampleCatalogueRules.enabledDocuments(documents, enabled: enabled, country: item["country"] as? String ?? "")
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

  func testEnabledCountryCases() async throws {
    for item in try cases("enabledCountries") {
      let (documents, enabled) = try await enabledInput(item)
      let actual = UseSmileIDSampleCatalogueRules.enabledCountries(documents, enabled: enabled).map { [$0.code, $0.name] }
      let expected = (item["expected"] as? [[String: String]] ?? []).map { [$0["code"] ?? "", $0["name"] ?? ""] }
      XCTAssertEqual(actual, expected, item["name"] as? String ?? "")
    }
  }

  func testFailureCases() throws {
    let failures = try section("failures")
    XCTAssertEqual(failures["default"] as? String, UseSmileIDSampleCatalogueRules.defaultAdvice)
    for item in try cases("failures") {
      let status = item["status"] as? Int
      XCTAssertEqual(UseSmileIDSampleCatalogueRules.advice(status: status), item["supportingText"] as? String, "\(String(describing: status))")
    }
  }

  func testCaptureAsCases() throws {
    for item in try cases("captureAs") {
      let name = item["name"] as? String ?? ""
      let expected = try XCTUnwrap(item["expected"] as? [String: Any])
      let document = try document(XCTUnwrap(item["document"] as? [String: Any]))
      let resolved = useSmileIDSampleResolvedCaptureAs(
        document: document,
        override: UseSmileIDSampleCaptureAs(rawValue: item["captureAs"] as? String ?? ""),
        genericDocument: (item["genericDocument"] as? [String: Any]).map(genericDocument) ?? UseSmileIDSampleGenericDocument()
      )
      XCTAssertEqual(resolved.captureAs == .genericDocument ? "generic" : resolved.captureAs.rawValue, expected["documentType"] as? String, name)
      if resolved.captureAs == .genericDocument {
        XCTAssertEqual(resolved.genericDocument.displayName, expected["displayName"] as? String, name)
        XCTAssertEqual(resolved.genericDocument.hasBackSide, expected["hasBackSide"] as? Bool, name)
        XCTAssertEqual(resolved.genericDocument.orientation.rawValue, expected["orientation"] as? String, name)
      }
      XCTAssertEqual(resolved.matched, expected["matched"] as? Bool, name)
      XCTAssertEqual(resolved.captureBothSides, expected["captureBothSides"] as? Bool, name)
      XCTAssertEqual(resolved.triggerText(), expected["triggerText"] as? String, name)
      let match = useSmileIDSampleResolvedCaptureAs(document: document, override: nil, genericDocument: UseSmileIDSampleGenericDocument())
      XCTAssertEqual(match.matchRowLabel, expected["matchRowLabel"] as? String, name)
    }
  }

  func testCaptureAsResetCases() throws {
    let resets = try XCTUnwrap(try section("captureAs")["resets"] as? [String: Any])
    for item in try XCTUnwrap(resets["cases"] as? [[String: Any]]) {
      var details = UseSmileIDSampleIdDetails()
      details.choose(country: UseSmileIDSampleCountry(code: "ZA", name: "South Africa"))
      try details.choose(document: document(XCTUnwrap(item["document"] as? [String: Any])))
      details.captureAsOverride = UseSmileIDSampleCaptureAs(rawValue: item["captureAs"] as? String ?? "")
      let change = try XCTUnwrap(item["change"] as? [String: Any])
      if let next = change["document"] as? [String: Any] {
        details.choose(document: document(next))
      }
      if let country = change["country"] as? [String: String] {
        details.choose(country: UseSmileIDSampleCountry(code: country["code"] ?? "", name: country["name"] ?? ""))
      }
      XCTAssertEqual(details.captureAsOverride, UseSmileIDSampleCaptureAs(rawValue: item["expected"] as? String ?? ""), item["name"] as? String ?? "")
    }
  }

  func testTheTriggerPlaceholderIsTheSpecs() throws {
    XCTAssertEqual(try section("captureAs")["triggerPlaceholder"] as? String, UseSmileIDSampleCaptureAs.matchDocumentLabel)
    XCTAssertNil(UseSmileIDSampleCaptureAs(rawValue: UseSmileIDSampleCaptureAs.matchDocumentId))
  }

  private func document(_ row: [String: Any]) -> UseSmileIDSampleDocument {
    UseSmileIDSampleDocument(
      code: row["code"] as? String ?? "",
      subType: row["subType"] as? String,
      name: row["name"] as? String ?? "",
      hasBack: row["hasBack"] as? Bool ?? true,
      format: row["format"] as? Int ?? 0
    )
  }

  private func genericDocument(_ sheet: [String: Any]) -> UseSmileIDSampleGenericDocument {
    UseSmileIDSampleGenericDocument(
      displayName: sheet["displayName"] as? String ?? "",
      hasBackSide: sheet["hasBackSide"] as? Bool ?? true,
      orientation: UseSmileIDSampleDocumentOrientation(rawValue: sheet["orientation"] as? String ?? "") ?? .landscape,
      aspectRatio: UseSmileIDSampleAspectRatio(rawValue: sheet["aspectRatio"] as? String ?? "") ?? .off
    )
  }

  func testARowTheProductDoesNotListIsDroppedWithItsOverride() {
    let greenBook = UseSmileIDSampleDocument(code: "IDENTITY_CARD", subType: "green_book", name: "Green Book", hasBack: false, format: 7)
    var details = UseSmileIDSampleIdDetails(document: greenBook, captureAsOverride: .passport)
    details.keepDocumentListed(on: .documentVerification)
    XCTAssertEqual(details.document, greenBook)
    details.keepDocumentListed(on: .enhancedDocumentVerification)
    XCTAssertNil(details.document)
    XCTAssertNil(details.captureAsOverride)
  }
}
