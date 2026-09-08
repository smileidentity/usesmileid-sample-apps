import SampleUI
@testable import UseSmileIDSample
import XCTest

final class UseSmileIDSampleCameraHoldTest: XCTestCase {
  func testEachProductHoldsTheLensItCapturesWith() {
    XCTAssertEqual(UseSmileIDSampleProduct.smartSelfieEnrollment.holdLens, .front)
    XCTAssertEqual(UseSmileIDSampleProduct.smartSelfieAuth.holdLens, .front)
    XCTAssertEqual(UseSmileIDSampleProduct.biometricKyc.holdLens, .front)
    XCTAssertEqual(UseSmileIDSampleProduct.documentVerification.holdLens, .back)
    XCTAssertEqual(UseSmileIDSampleProduct.enhancedDocumentVerification.holdLens, .back)
    XCTAssertEqual(UseSmileIDSampleProduct.enhancedKyc.holdLens, .back)
  }

  func testAHoldDescribesItselfInTheArgumentsWords() {
    XCTAssertEqual(UseSmileIDSampleHoldCamera.keep.description, "holdCamera=keep")
    XCTAssertEqual(UseSmileIDSampleHoldCamera.millis(500).description, "holdCamera=500ms")
  }
}
