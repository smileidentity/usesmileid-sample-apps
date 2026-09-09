@testable import SampleUI
import XCTest

final class UseSmileIDSampleLicensesTest: XCTestCase {
  private let licenses = UseSmileIDSampleLicenses.bundled()

  func testTheGeneratedAssetShipsInTheLibraryBundle() {
    XCTAssertFalse(licenses.isEmpty, "the generated asset did not ship with the library bundle")
  }

  func testEveryComponentCarriesALicence() {
    for notice in licenses.components {
      XCTAssertFalse(notice.component.isEmpty)
      XCTAssertFalse(notice.licenseId.isEmpty, "\(notice.component) carries no licence id")
      XCTAssertFalse(notice.licenseName.isEmpty, "\(notice.component) carries no licence name")
    }
  }

  func testNothingIsListedAsUnknown() {
    for notice in licenses.components {
      XCTAssertFalse(notice.licenseId.lowercased().contains("unknown"), notice.component)
      XCTAssertFalse(notice.licenseName.lowercased().contains("unknown"), notice.component)
    }
  }

  func testEveryComponentOffersATextOrThePageThatCarriesOne() {
    for notice in licenses.components {
      XCTAssertTrue(
        notice.text?.isEmpty == false || notice.url?.isEmpty == false,
        "\(notice.component) offers neither a text nor a page"
      )
    }
  }

  func testBothShippingRootsAreListed() {
    let names = Set(licenses.components.map(\.component))
    XCTAssertTrue(names.contains("lottie-spm"), "the walk lost a package the app links")
    XCTAssertTrue(names.contains("sentry-cocoa"), "the walk lost a package the app links")
  }

  func testTheSdkItselfIsNotAThirdPartyNotice() {
    for notice in licenses.components {
      let name = notice.component.lowercased()
      XCTAssertFalse(name.contains("ios-spm"), "a partner licenses the SDK from Smile ID")
      XCTAssertFalse(name.contains("usesmileid"), "a partner licenses the SDK from Smile ID")
    }
  }

  /// Why the walk starts from the linked products rather than from `Package.resolved`, which pins these.
  func testTestOnlyPackagesShipWithNothing() {
    let shipped = Set(licenses.components.map { $0.component.lowercased() })
    for pin in ["swift-snapshot-testing", "swift-syntax", "swift-custom-dump", "xctest-dynamic-overlay"] {
      XCTAssertFalse(shipped.contains(pin), "\(pin) is test-only")
    }
  }

  func testAVendoredNoticeTravelsWithTheComponentThatVendorsIt() {
    let nested = licenses.components.filter { $0.component.contains("/") }
    XCTAssertFalse(nested.isEmpty, "a component that vendors third-party code must list what it vendors")
    let names = Set(licenses.components.map(\.component))
    for notice in nested {
      XCTAssertFalse(notice.text?.isEmpty ?? true, "\(notice.component) vendored a notice with no text")
      let host = String(notice.component.prefix(while: { $0 != "/" }))
      XCTAssertTrue(names.contains(host), "\(notice.component) is listed without its host")
    }
  }

  /// The schema divergence from Android's asset: its texts are holder-free templates keyed by licence,
  /// and a LICENSE file is not, so sharing one copy would attribute one component's holder to another.
  func testTheMitComponentsShareNeitherATextNorAHolder() {
    let mit = licenses.components.filter { $0.licenseId == "MIT" }.compactMap(\.text)
    XCTAssertGreaterThan(mit.count, 1, "expected more than one MIT component")
    XCTAssertEqual(Set(mit).count, mit.count, "two MIT components share one text")
    let holders = mit.compactMap { text in
      text.split(separator: "\n").first { $0.lowercased().contains("copyright") }.map(String.init)
    }
    XCTAssertEqual(holders.count, mit.count, "an MIT text carries no copyright line")
    XCTAssertEqual(Set(holders).count, holders.count, "two MIT components name one holder")
  }

  func testTheApacheTextShipsRatherThanBeingLinked() {
    let apache = licenses.components.filter { $0.licenseId == "Apache-2.0" }
    XCTAssertFalse(apache.isEmpty)
    for notice in apache {
      XCTAssertTrue(notice.text?.contains("Apache License") ?? false, notice.component)
    }
  }

  func testAMalformedAssetReadsAsNoNoticesRatherThanCrashing() {
    XCTAssertTrue(UseSmileIDSampleLicenses.decode(Data("{ not json".utf8)).isEmpty)
    XCTAssertTrue(UseSmileIDSampleLicenses.decode(Data()).isEmpty)
    XCTAssertTrue(UseSmileIDSampleLicenses.decode(Data(#"{"components":[{"component":"a"}]}"#.utf8)).isEmpty)
  }

  func testAnAbsentAssetIsTheEmptyStateRatherThanAFailure() {
    XCTAssertTrue(UseSmileIDSampleLicenses.bundled(in: Bundle(for: Self.self)).isEmpty)
  }

  /// No shipped component takes this path, so the decode is what covers it: the reviewed OVERRIDES
  /// table is how a component whose text stays inside it gets listed.
  func testAComponentWhoseTextStaysInsideItDecodesToALink() throws {
    let asset = #"""
    {"components": [{
      "component": "vendored", "version": "1.0.0", "licenseId": "Vendor-1.0",
      "licenseName": "Vendor Licence", "text": null, "url": "https://example.com/licence"
    }]}
    """#
    let notice = try XCTUnwrap(UseSmileIDSampleLicenses.decode(Data(asset.utf8)).components.first)
    XCTAssertNil(notice.text)
    XCTAssertEqual("https://example.com/licence", notice.url)
    XCTAssertEqual("1.0.0 · Vendor Licence", notice.subtitle)
  }

  /// A vendored notice is not separately pinned, so its row would read " · MIT License" if the
  /// separator were unconditional the way the Compose twin's is.
  func testAVersionIsShownOnlyWhereThereIsOne() {
    XCTAssertEqual("MIT License", Self.notice(version: "").subtitle)
    XCTAssertEqual("1.2 · MIT License", Self.notice(version: "1.2").subtitle)
  }

  private static func notice(version: String) -> UseSmileIDSampleNotice {
    UseSmileIDSampleNotice(
      component: "a", version: version, licenseId: "MIT", licenseName: "MIT License", text: "t"
    )
  }
}
