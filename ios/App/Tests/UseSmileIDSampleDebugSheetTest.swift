import SwiftUI
@testable import UseSmileIDSample
import XCTest

/// A debug sheet opens only in a debug build whose extension draws it; a release build, no extension or an unknown id closes it at once.
@MainActor
final class UseSmileIDSampleDebugSheetTest: XCTestCase {
  func testADebugBuildOpensASheetItsExtensionDraws() {
    XCTAssertTrue(useSmileIDSampleDebugSheetOpens(debugBuild: true, extension: TimingsExtension.self, sheetId: "captureTimings"))
  }

  func testAReleaseBuildNeverOpensIt() {
    XCTAssertFalse(useSmileIDSampleDebugSheetOpens(debugBuild: false, extension: TimingsExtension.self, sheetId: "captureTimings"))
  }

  func testAnIdTheExtensionDoesNotDrawCloses() {
    XCTAssertFalse(useSmileIDSampleDebugSheetOpens(debugBuild: true, extension: TimingsExtension.self, sheetId: "unknown"))
  }

  func testABuildWithNoExtensionHasNothingToDraw() {
    XCTAssertFalse(useSmileIDSampleDebugSheetOpens(debugBuild: true, extension: nil, sheetId: "captureTimings"))
  }
}

/// An extension that draws one debug sheet.
private enum TimingsExtension: UseSmileIDSampleShellExtending {
  static func hasDebugSheet(_ sheetId: String) -> Bool {
    sheetId == "captureTimings"
  }
}
