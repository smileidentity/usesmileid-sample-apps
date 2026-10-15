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

  func testEveryCaseMatchesTheSpec() throws {
    let cases = try XCTUnwrap(try file()["cases"] as? [[String: Any]])
    XCTAssertFalse(cases.isEmpty)
    for item in cases {
      let name = item["name"] as? String ?? ""
      let product = try XCTUnwrap(UseSmileIDSampleProduct(rawValue: item["product"] as? String ?? ""), name)
      let fields = (item["fieldsToCollect"] as? [String: Any]).map { UseSmileIDSampleCatalogueJson.fieldsToCollect(section: $0) }
      let bound = item["bindings"] as? [String: Bool] ?? [:]
      let bindings = UseSmileIDSampleTokenBindings(
        givenNames: bound["givenNames"] == true,
        lastName: bound["lastName"] == true,
        email: bound["email"] == true,
        phoneNumber: bound["phoneNumber"] == true
      )
      let requirement = UseSmileIDSampleUserDetailsRequirement(bindings: bindings, product: product, fieldsToCollect: fields)
      let expect = try XCTUnwrap(item["expect"] as? [String: String], name)
      XCTAssertEqual(outcome(requirement, .firstName), expect["firstName"], "\(name): firstName")
      XCTAssertEqual(outcome(requirement, .lastName), expect["lastName"], "\(name): lastName")
      XCTAssertEqual(requirement.contact ? "ask" : "provided", expect["contact"], "\(name): contact")
    }
  }

  func testAConfigThatDoesNotParseKeepsTheTokenRule() {
    XCTAssertNil(UseSmileIDSampleCatalogueJson.fieldsToCollect(Data("not json".utf8)))
    XCTAssertEqual(UseSmileIDSampleCatalogueJson.fieldsToCollect(Data(#"{"products": {}}"#.utf8)), [:])
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
