import Foundation
@testable import SampleUI
import UseSmileID
import XCTest

/// How a failure the SDK hands `onResult` picks its row of `spec/error-handling.json`.
final class UseSmileIDSampleFailureRowTest: XCTestCase {
  func testARefusedSubmissionResolvesByItsStatus() {
    XCTAssertEqual(NetworkServerException(statusCode: 429).useSmileIDSampleErrorResolution?.id, "rateLimited")
    XCTAssertEqual(NetworkServerException(statusCode: 503).useSmileIDSampleErrorResolution?.id, "serverError")
    XCTAssertEqual(NetworkServerException(statusCode: 403).useSmileIDSampleErrorResolution?.id, "notEnabled")
  }

  func testTheServersMessageTellsRowsOfOneStatusApart() {
    let idNumber = NetworkServerException(statusCode: 400, message: "Invalid ID number format for the specified country and ID type.")
    XCTAssertEqual(idNumber.useSmileIDSampleErrorResolution?.id, "idNumberInvalid")
    let sdkVersion = NetworkServerException(statusCode: 403, message: "SDK version not allowed.")
    XCTAssertEqual(sdkVersion.useSmileIDSampleErrorResolution?.id, "sdkVersionNotAllowed")
    XCTAssertEqual(NetworkServerException(statusCode: 400).useSmileIDSampleErrorResolution?.id, "requestInvalid")
  }

  func testATimeoutAndALostConnectionResolveAsTransportFailures() {
    XCTAssertEqual(NetworkTimeoutException().useSmileIDSampleErrorResolution?.id, "timeout")
    XCTAssertEqual(NetworkTransportException().useSmileIDSampleErrorResolution?.id, "noConnection")
  }

  func testATransportFailureThatWouldFailTheSameWayAgainHasNoRow() {
    XCTAssertNil(NetworkTransportException(errorCode: .requestFailed).useSmileIDSampleErrorResolution)
  }

  func testAFailureNoSubmissionReturnedHasNoRow() {
    XCTAssertNil(CocoaError(.fileNoSuchFile).useSmileIDSampleErrorResolution)
  }
}
