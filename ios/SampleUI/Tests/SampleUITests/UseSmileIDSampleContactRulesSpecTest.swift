import Foundation
@testable import SampleUI
import XCTest

/// spec/contact-rules.json: what each email and phone number submits, and that no form checks either.
final class UseSmileIDSampleContactRulesSpecTest: XCTestCase {
  private func cases() throws -> [[String: Any]] {
    try XCTUnwrap(try UseSmileIDSampleSpecFiles.object("contact-rules.json")["cases"] as? [[String: Any]])
  }

  private func field(_ name: String) -> UseSmileIDSampleUserField {
    name == "email" ? .email : .phone
  }

  func testEveryCaseSubmitsAsTheSpecSays() throws {
    let cases = try cases()
    XCTAssertFalse(cases.isEmpty)
    for item in cases {
      let field = field(item["field"] as? String ?? "")
      let value = item["value"] as? String ?? ""
      XCTAssertEqual(UseSmileIDSampleContactRules.submitted(field, value), item["submits"] as? String, "\(field) '\(value)'")
    }
  }

  func testNoContactHoldsAFormBack() throws {
    for item in try cases() where !(item["submits"] as? String ?? "").isEmpty {
      let value = item["value"] as? String ?? ""
      let isEmail = item["field"] as? String == "email"
      let details = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: isEmail ? value : "", phone: isEmail ? "" : value)
      XCTAssertTrue(details.satisfies(UseSmileIDSampleUserDetailsRequirement()), "'\(value)'")
      let draft = UseSmileIDSampleNewProfile(name: "Uptech", firstName: "Ada", lastName: "Okafor", email: details.email, phone: details.phone)
      XCTAssertTrue(draft.canCreate, "'\(value)'")
    }
  }

  func testTheSubmittedPhoneHasNoSeparators() {
    XCTAssertEqual(UseSmileIDSampleUserDetails(phone: "+254 700 000 000").submittedPhone, "+254700000000")
    XCTAssertNil(UseSmileIDSampleUserDetails(phone: "  ").submittedPhone)
  }
}
