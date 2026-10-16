import Foundation
@testable import SampleUI
import XCTest

/// spec/user-details-fields.json: which user-details rows the form shows for a product.
final class UseSmileIDSampleUserDetailsFieldsSpecTest: XCTestCase {
  private func file() throws -> [String: Any] {
    try UseSmileIDSampleSpecFiles.object("user-details-fields.json")
  }

  func testEveryProductReadsTheSpecKey() throws {
    let keys = try XCTUnwrap(try file()["productKeys"] as? [String: Any])
    XCTAssertEqual(Set(keys.keys), Set(UseSmileIDSampleProduct.allCases.map(\.rawValue)))
    for product in UseSmileIDSampleProduct.allCases {
      XCTAssertEqual(product.fieldsToCollectKey, keys[product.rawValue] as? String, product.rawValue)
    }
  }

  func testOnlyTheSpecProductsReadIdTypeEntries() throws {
    let ids = try XCTUnwrap(try file()["idTypeProducts"] as? [String])
    XCTAssertEqual(Set(UseSmileIDSampleProduct.allCases.filter(\.readsIdTypes).map(\.rawValue)), Set(ids))
  }

  func testEveryCaseMatchesTheSpec() throws {
    let cases = try XCTUnwrap(try file()["cases"] as? [[String: Any]])
    XCTAssertFalse(cases.isEmpty)
    for item in cases {
      let name = item["name"] as? String ?? ""
      let product = try XCTUnwrap(UseSmileIDSampleProduct(rawValue: item["product"] as? String ?? ""), name)
      let fields = (item["fieldsToCollect"] as? [String: Any]).map { UseSmileIDSampleCatalogueJson.fieldsToCollect(section: $0) }
      let idTypeFields = (item["products"] as? [String: Any]).map { UseSmileIDSampleCatalogueJson.idTypeFields(section: $0) }
      let bound = item["bindings"] as? [String: Bool] ?? [:]
      let bindings = UseSmileIDSampleTokenBindings(
        givenNames: bound["givenNames"] == true,
        lastName: bound["lastName"] == true,
        email: bound["email"] == true,
        phoneNumber: bound["phoneNumber"] == true
      )
      let requirement = UseSmileIDSampleUserDetailsRequirement(
        bindings: bindings,
        product: product,
        fieldsToCollect: fields,
        idTypeFields: idTypeFields
      )
      let expect = try XCTUnwrap(item["expect"] as? [String: String], name)
      XCTAssertEqual(outcome(requirement, .firstName), expect["firstName"], "\(name): firstName")
      XCTAssertEqual(outcome(requirement, .lastName), expect["lastName"], "\(name): lastName")
      XCTAssertEqual(requirement.contact ? "ask" : "provided", expect["contact"], "\(name): contact")
      let typed = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@example.com")
      for pick in item["submit"] as? [[String: String]] ?? [] {
        let entry = idTypeFields.entry(for: product, country: pick["country"], idType: pick["idType"])
        let sent = typed.withoutHiddenNames(UseSmileIDSampleUserDetailsRequirement(), entry: entry)
        let at = "\(name): \(pick["country"] ?? "") \(pick["idType"] ?? "")"
        XCTAssertEqual(sent.firstName.isEmpty ? "dropped" : "sent", pick["firstName"], "\(at) firstName")
        XCTAssertEqual(sent.lastName.isEmpty ? "dropped" : "sent", pick["lastName"], "\(at) lastName")
      }
    }
  }

  func testAConfigThatDoesNotParseKeepsTheTokenRule() {
    XCTAssertNil(UseSmileIDSampleCatalogueJson.fieldsToCollect(Data("not json".utf8)))
    XCTAssertEqual(UseSmileIDSampleCatalogueJson.fieldsToCollect(Data(#"{"products": {}}"#.utf8)), [:])
    XCTAssertNil(UseSmileIDSampleCatalogueJson.idTypeFields(Data("not json".utf8)))
    XCTAssertEqual(UseSmileIDSampleCatalogueJson.idTypeFields(Data(#"{"fields_to_collect": {}}"#.utf8)), [:])
  }

  func testAnIdTypeEntryItCannotReadIsSkipped() throws {
    let body = #"{"enhanced_kyc": {"KE": [{"label": "No key"}, {"key_name": "NATIONAL_ID", "fields": [{"key_name": "given_names", "required": true}, {"label": "no key"}]}], "GH": "not a list"}, "biometric_kyc": "not an object"}"#
    let section = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
    XCTAssertEqual(
      UseSmileIDSampleCatalogueJson.idTypeFields(section: section),
      [
        "enhanced_kyc": ["KE": ["NATIONAL_ID": [UseSmileIDSampleApiField(name: "given_names", required: true)]], "GH": [:]],
        "biometric_kyc": [:]
      ]
    )
  }

  func testHiddenNamesNeverHoldTheFormBackAndSubmitNothing() {
    let requirement = UseSmileIDSampleUserDetailsRequirement(firstName: false, lastName: false, hidden: [.firstName, .lastName])
    let typed = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@example.com")
    XCTAssertTrue(UseSmileIDSampleUserDetails(email: "ada@example.com").satisfies(requirement))
    XCTAssertFalse(requirement.supplies(.firstName))
    XCTAssertEqual(typed.withoutHiddenNames(requirement), UseSmileIDSampleUserDetails(email: "ada@example.com"))
    XCTAssertEqual(typed.withoutHiddenNames(UseSmileIDSampleUserDetailsRequirement()), typed)
  }

  private func outcome(_ requirement: UseSmileIDSampleUserDetailsRequirement, _ field: UseSmileIDSampleUserField) -> String {
    if !requirement.shows(field) {
      return "hidden"
    }
    return requirement.supplies(field) ? "provided" : "ask"
  }
}
