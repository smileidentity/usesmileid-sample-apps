@testable import SampleUI
import XCTest

final class UseSmileIDSampleIdDetailsTest: XCTestCase {
  func testAllThreeFieldsAreNeeded() {
    XCTAssertFalse(UseSmileIDSampleIdDetails().isComplete)
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: .kenya, idNumber: "A012345678").isComplete)
    XCTAssertFalse(UseSmileIDSampleIdDetails(country: .kenya, idType: .nationalId).isComplete)
    XCTAssertFalse(
      UseSmileIDSampleIdDetails(country: .kenya, idType: .nationalId, idNumber: "   ").isComplete
    )
    XCTAssertTrue(
      UseSmileIDSampleIdDetails(country: .kenya, idType: .nationalId, idNumber: "A012345678").isComplete
    )
  }

  func testNoCountryOffersNoIdType() {
    XCTAssertTrue(UseSmileIDSampleIdType.of(nil).isEmpty)
  }

  func testTheIdTypeListIsCountrySpecific() {
    XCTAssertEqual(
      UseSmileIDSampleIdType.of(.nigeria),
      [.nationalId, .passport, .driversLicense, .voterId]
    )
    XCTAssertEqual(UseSmileIDSampleIdType.of(.kenya), [.nationalId, .passport, .driversLicense])
    XCTAssertEqual(UseSmileIDSampleIdType.of(.ghana), [.nationalId, .passport, .voterId])
    XCTAssertEqual(UseSmileIDSampleIdType.of(.uganda), [.nationalId, .passport])
  }

  /// Both halves cross a wire, so a rename is an API change, not a refactor.
  func testTheCodesAndIdsAreTheWireValues() {
    XCTAssertEqual(
      UseSmileIDSampleCountry.allCases.map(\.code),
      ["NG", "KE", "GH", "ZA", "UG", "TZ", "RW"]
    )
    XCTAssertEqual(
      UseSmileIDSampleIdType.allCases.map(\.id),
      ["NATIONAL_ID", "PASSPORT", "DRIVERS_LICENSE", "VOTER_ID"]
    )
  }

  /// An empty query lists everything. Foundation answers false to `contains("")` where Kotlin
  /// answers true, so a literal port of the Compose filter opens both pickers empty.
  func testAnEmptyQueryMatchesEverything() {
    XCTAssertEqual(UseSmileIDSampleCountry.matching("").count, UseSmileIDSampleCountry.allCases.count)
    XCTAssertEqual(UseSmileIDSampleCountry.matching("   ").count, UseSmileIDSampleCountry.allCases.count)
    XCTAssertEqual(
      UseSmileIDSampleIdType.of(.ghana, matching: ""),
      UseSmileIDSampleIdType.of(.ghana)
    )
  }

  func testTheSearchIsCaseInsensitiveAndSubstring() {
    XCTAssertEqual(UseSmileIDSampleCountry.matching("ken"), [.kenya])
    XCTAssertEqual(UseSmileIDSampleCountry.matching("AFRICA"), [.southAfrica])
    XCTAssertTrue(UseSmileIDSampleCountry.matching("Atlantis").isEmpty)
    XCTAssertEqual(UseSmileIDSampleIdType.of(.nigeria, matching: "pass"), [.passport])
  }

  /// A search cannot reach an ID type the country does not offer.
  func testTheSearchStaysInsideTheCountry() {
    XCTAssertTrue(UseSmileIDSampleIdType.of(.uganda, matching: "voter").isEmpty)
    XCTAssertTrue(UseSmileIDSampleIdType.of(nil, matching: "").isEmpty)
  }

  func testEveryCountryHasAFlag() {
    for country in UseSmileIDSampleCountry.allCases {
      XCTAssertFalse(country.flag.isEmpty, country.code)
      XCTAssertFalse(country.label.isEmpty, country.code)
    }
  }
}
