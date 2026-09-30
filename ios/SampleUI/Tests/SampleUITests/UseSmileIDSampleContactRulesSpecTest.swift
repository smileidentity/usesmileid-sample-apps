import Foundation
@testable import SampleUI
import XCTest

/// spec/contact-rules.json: which emails and phone numbers pass, what each submits, and the error it shows.
final class UseSmileIDSampleContactRulesSpecTest: XCTestCase {
  private func file() throws -> [String: Any] {
    try UseSmileIDSampleSpecFiles.object("contact-rules.json")
  }

  private func field(_ name: String) -> UseSmileIDSampleUserField {
    name == "email" ? .email : .phone
  }

  func testEveryCaseMatchesTheSpec() throws {
    let cases = try XCTUnwrap(try file()["cases"] as? [[String: Any]])
    XCTAssertFalse(cases.isEmpty)
    for item in cases {
      let field = field(item["field"] as? String ?? "")
      let value = item["value"] as? String ?? ""
      let valid = try XCTUnwrap(item["valid"] as? Bool)
      XCTAssertEqual(UseSmileIDSampleContactRules.problem(field, value) == nil, valid, "\(field) '\(value)'")
      if valid {
        XCTAssertEqual(UseSmileIDSampleContactRules.submitted(field, value), item["submits"] as? String, "\(field) '\(value)'")
      }
    }
  }

  func testTheErrorsAreTheSpecSentences() throws {
    let email = try XCTUnwrap(try file()["email"] as? [String: Any])
    let phone = try XCTUnwrap(try file()["phone"] as? [String: Any])
    XCTAssertEqual(UseSmileIDSampleContactRules.problem(.email, "ada"), email["error"] as? String)
    XCTAssertEqual(UseSmileIDSampleContactRules.problem(.phone, "0700"), phone["error"] as? String)
  }

  func testABadContactKeepsTheFormFromContinuingAndABlankOneDoesNot() {
    let requirement = UseSmileIDSampleUserDetailsRequirement()
    let named = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@example.com")
    XCTAssertTrue(named.satisfies(requirement))
    XCTAssertNil(named.contactProblem)
    var badPhone = named
    badPhone.phone = "0700000000"
    XCTAssertFalse(badPhone.satisfies(requirement))
    var badEmail = named
    badEmail.email = "ada@example"
    XCTAssertFalse(badEmail.satisfies(requirement))
  }

  func testTheSubmittedPhoneHasNoSeparators() {
    XCTAssertEqual(UseSmileIDSampleUserDetails(phone: "+254 700 000 000").submittedPhone, "+254700000000")
    XCTAssertNil(UseSmileIDSampleUserDetails(phone: "  ").submittedPhone)
  }
}
