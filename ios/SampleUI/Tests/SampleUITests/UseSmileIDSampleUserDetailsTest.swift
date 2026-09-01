@testable import SampleUI
import XCTest

final class UseSmileIDSampleUserDetailsTest: XCTestCase {
  func testBothNamesAndOneContactSatisfyTheUnboundRule() {
    let requirement = UseSmileIDSampleUserDetailsRequirement()
    XCTAssertFalse(UseSmileIDSampleUserDetails(firstName: "Kwame").satisfies(requirement))
    XCTAssertFalse(
      UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante").satisfies(requirement)
    )
    XCTAssertTrue(
      UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante", phone: "+254700000000")
        .satisfies(requirement)
    )
  }

  func testWhitespaceIsNotAName() {
    let details = UseSmileIDSampleUserDetails(firstName: "  ", lastName: "Asante", email: "a@b.com")
    XCTAssertFalse(details.satisfies(UseSmileIDSampleUserDetailsRequirement()))
    XCTAssertFalse(details.isComplete)
  }

  func testABoundFieldStopsBeingAsked() {
    let requirement = UseSmileIDSampleUserDetailsRequirement(firstName: false, lastName: false)
    XCTAssertTrue(requirement.supplies(.firstName))
    XCTAssertTrue(requirement.supplies(.lastName))
    // "One of" — a bound email would leave phone askable, so neither row is individually supplied.
    XCTAssertFalse(requirement.supplies(.email))
    XCTAssertFalse(requirement.supplies(.phone))
    XCTAssertTrue(UseSmileIDSampleUserDetails(phone: "+254700000000").satisfies(requirement))
  }

  func testThePromptNamesWhatIsOutstanding() {
    XCTAssertEqual(
      UseSmileIDSampleUserDetailsRequirement().prompt,
      "Required: first name, last name, an email or phone number."
    )
    XCTAssertEqual(
      UseSmileIDSampleUserDetailsRequirement(firstName: false, lastName: false).prompt,
      "An email or phone number is required."
    )
    XCTAssertEqual(
      UseSmileIDSampleUserDetailsRequirement(firstName: false, lastName: false, contact: false).prompt,
      "Tap any field to edit."
    )
  }

  func testAContactRowDropsOptionalOnceItIsRequired() {
    let asked = UseSmileIDSampleUserDetailsRequirement()
    XCTAssertEqual(asked.label(for: .email), "Email")
    XCTAssertEqual(asked.label(for: .phone), "Phone")
    let bound = UseSmileIDSampleUserDetailsRequirement(contact: false)
    XCTAssertEqual(bound.label(for: .email), "Email (optional)")
    XCTAssertEqual(bound.label(for: .phone), "Phone (optional)")
  }

  func testWritingAFieldTouchesOnlyThatField() {
    let details = UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante")
    XCTAssertEqual(
      UseSmileIDSampleUserField.email.write(details, "a@b.com"),
      UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante", email: "a@b.com")
    )
    for field in UseSmileIDSampleUserField.allCases {
      XCTAssertEqual(field.read(field.write(details, "x")), "x")
    }
  }

  func testTheFieldIdsAreTheirCaseNames() {
    XCTAssertEqual(UseSmileIDSampleUserField.allCases.map(\.id), ["firstName", "lastName", "email", "phone"])
  }
}
