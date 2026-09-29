@testable import SampleUI
import XCTest

final class UseSmileIDSampleIdDetailsTest: XCTestCase {
  private let kenya = UseSmileIDSampleCountry(code: "KE", name: "Kenya")
  private let nationalId = UseSmileIDSampleKycIdType(id: "NATIONAL_ID", type: "NATIONAL_ID", label: "National ID", regex: "^[0-9]{1,9}$")

  func testKycNeedsACountryATypeAndANumberThatFitsIt() {
    XCTAssertFalse(UseSmileIDSampleIdDetails().isComplete(.kyc))
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: kenya, idNumber: "12345678").isComplete(.kyc))
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: kenya, idType: nationalId).isComplete(.kyc))
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: kenya, idType: nationalId, idNumber: "   ").isComplete(.kyc))
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: kenya, idType: nationalId, idNumber: "AO12345678").isComplete(.kyc))
    XCTAssertTrue(UseSmileIDSampleIdDetails(country: kenya, idType: nationalId, idNumber: " 12345678 ").isComplete(.kyc))
  }

  func testTheDocumentProductsNeedNoNumber() {
    let passport = UseSmileIDSampleDocument(code: "PASSPORT", name: "Passport", hasBack: false, format: 3)
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: kenya).isComplete(.document))
    XCTAssertTrue(UseSmileIDSampleIdDetails(country: kenya, document: passport).isComplete(.document))
  }

  func testTheFlagComesFromTheCodeAlone() {
    XCTAssertEqual(kenya.flag, "\u{1F1F0}\u{1F1EA}")
    XCTAssertEqual(UseSmileIDSampleCountry(code: "ZA", name: "South Africa").flag, "\u{1F1FF}\u{1F1E6}")
    XCTAssertEqual(UseSmileIDSampleCountry(code: "", name: "Nowhere").flag, "\u{1F30D}")
  }

  func testASubTypeRowIsNamedAfterItsParent() {
    let greenBook = UseSmileIDSampleDocument(code: "IDENTITY_CARD", subType: "green_book", name: "Green Book", hasBack: false, format: 7)
    XCTAssertEqual(greenBook.id, "IDENTITY_CARD_green_book")
  }

  func testAnEmptyQueryMatchesEverything() {
    XCTAssertTrue("Kenya".matches(""))
    XCTAssertTrue("Kenya".matches(" ken "))
    XCTAssertFalse("Kenya".matches("uganda"))
  }
}
