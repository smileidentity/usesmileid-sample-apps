import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

/// spec/catalogue-rules.json captureAs: what "Capture as" hands the SDK, and that the server always gets the code.
@MainActor
final class UseSmileIDSampleDocumentCaptureMappingTest: XCTestCase {
  func testEveryCaseMapsAsTheSpecSays() throws {
    let section = try XCTUnwrap(try UseSmileIDSampleSpec.object("catalogue-rules.json")["captureAs"] as? [String: Any])
    let cases = try XCTUnwrap(section["cases"] as? [[String: Any]])
    XCTAssertGreaterThanOrEqual(cases.count, 6)
    for item in cases {
      let name = item["name"] as? String ?? ""
      let details = try details(item)
      let expected = try XCTUnwrap(item["expected"] as? [String: Any])
      let type = useSmileIDSampleDocumentType(details)
      switch expected["documentType"] as? String {
      case "passport": XCTAssertEqual(type, .passport, name)
      case "greenBook": XCTAssertEqual(type, .southAfricaGreenBook, name)
      default:
        guard case .genericDocument(let displayName, let hasBackSide, let orientation, let ratio) = type else {
          XCTFail("\(name): not a generic document")
          continue
        }
        XCTAssertEqual(displayName, expected["displayName"] as? String, name)
        XCTAssertEqual(hasBackSide, expected["hasBackSide"] as? Bool, name)
        if let expectedOrientation = expected["orientation"] as? String {
          XCTAssertEqual(orientation == .portrait ? "portrait" : "landscape", expectedOrientation, name)
        }
        if let expectedRatio = expected["knownAspectRatio"] as? Double {
          XCTAssertEqual(try Double(XCTUnwrap(ratio)), expectedRatio, accuracy: 0.0001, name)
        }
      }
      let snapshot = FlowLaunchSnapshot(product: .documentVerification, route: .fullscreen, idDetails: details)
      XCTAssertEqual(useSmileIDSampleIdParams(snapshot).documentVerification?.idType, expected["idType"] as? String, name)
    }
  }

  func testCaptureModeReachesTheSdkAsItsThreeValues() {
    XCTAssertEqual(UseSmileIDSampleCaptureMode.auto.sdk, .autoCapture)
    XCTAssertEqual(UseSmileIDSampleCaptureMode.manual.sdk, .manualCapture)
    XCTAssertEqual(UseSmileIDSampleCaptureMode.autoWithFallback.sdk, .autoCaptureWithManualFallback())
  }

  func testTheSettingsReachTheDocumentConfig() {
    let snapshot = FlowLaunchSnapshot(
      product: .documentVerification,
      route: .fullscreen,
      captureMode: .manual,
      galleryUpload: true,
      captureBothSides: false,
      allowSkipBack: true
    )
    let config = useSmileIDSampleDocumentCapture(snapshot)
    XCTAssertEqual(config.captureMode, .manualCapture)
    XCTAssertTrue(config.allowGalleryUpload)
    XCTAssertFalse(config.captureBothSides)
    XCTAssertTrue(config.allowSkipBack)
    let defaults = useSmileIDSampleDocumentCapture(FlowLaunchSnapshot(product: .documentVerification, route: .fullscreen))
    XCTAssertFalse(defaults.allowGalleryUpload)
    XCTAssertTrue(defaults.captureBothSides)
    XCTAssertFalse(defaults.allowSkipBack)
  }

  func testADocumentJobSendsTheDocumentEvenWithAnIdTypeLeftInTheForm() {
    let details = UseSmileIDSampleIdDetails(
      country: UseSmileIDSampleCountry(code: "KE", name: "Kenya"),
      idType: UseSmileIDSampleKycIdType(id: "NATIONAL_ID", type: "NATIONAL_ID", label: "National ID", regex: "^[0-9]{1,9}$"),
      document: UseSmileIDSampleDocument(code: "PASSPORT", name: "Passport", hasBack: false, format: 3)
    )
    let snapshot = FlowLaunchSnapshot(product: .documentVerification, route: .fullscreen, idDetails: details)
    XCTAssertEqual(useSmileIDSampleIdParams(snapshot).documentVerification?.idType, "PASSPORT")
  }

  func testAKycJobSendsTheNumberTrimmedAsTheFormCheckedIt() {
    let details = UseSmileIDSampleIdDetails(
      country: UseSmileIDSampleCountry(code: "KE", name: "Kenya"),
      idType: UseSmileIDSampleKycIdType(id: "NATIONAL_ID", type: "NATIONAL_ID", label: "National ID", regex: "^[0-9]{1,9}$"),
      idNumber: " 12345678 "
    )
    let snapshot = FlowLaunchSnapshot(product: .biometricKyc, route: .fullscreen, idDetails: details)
    XCTAssertEqual(useSmileIDSampleIdParams(snapshot).biometricKyc?.idNumber, "12345678")
  }

  private func details(_ item: [String: Any]) throws -> UseSmileIDSampleIdDetails {
    let document = try XCTUnwrap(item["document"] as? [String: Any])
    var details = try UseSmileIDSampleIdDetails(
      country: UseSmileIDSampleCountry(code: "ZA", name: "South Africa"),
      document: UseSmileIDSampleDocument(
        code: document["code"] as? String ?? "",
        subType: document["subType"] as? String,
        name: document["name"] as? String ?? "",
        hasBack: document["hasBack"] as? Bool ?? true,
        format: document["format"] as? Int ?? 1
      ),
      captureAs: XCTUnwrap(UseSmileIDSampleCaptureAs(rawValue: item["captureAs"] as? String ?? ""))
    )
    if let genericDocument = item["genericDocument"] as? [String: Any] {
      details.genericDocument = UseSmileIDSampleGenericDocument(
        displayName: genericDocument["displayName"] as? String ?? "",
        hasBackSide: genericDocument["hasBackSide"] as? Bool ?? true,
        orientation: UseSmileIDSampleDocumentOrientation(rawValue: genericDocument["orientation"] as? String ?? "") ?? .landscape,
        aspectRatio: UseSmileIDSampleAspectRatio(rawValue: genericDocument["aspectRatio"] as? String ?? "") ?? .off
      )
    }
    return details
  }
}
