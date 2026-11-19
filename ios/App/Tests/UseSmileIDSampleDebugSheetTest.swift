@testable import UseSmileIDSample
import XCTest

/// A debug sheet opens only in a debug build that has an extension to draw it; a release build closes it at once.
final class UseSmileIDSampleDebugSheetTest: XCTestCase {
  func testADebugBuildWithAnExtensionOpensTheSheet() {
    XCTAssertTrue(useSmileIDSampleDebugSheetOpens(debugBuild: true, hasExtension: true))
  }

  func testAReleaseBuildNeverOpensItEvenWithAnExtension() {
    XCTAssertFalse(useSmileIDSampleDebugSheetOpens(debugBuild: false, hasExtension: true))
  }

  func testABuildWithNoExtensionHasNothingToDraw() {
    XCTAssertFalse(useSmileIDSampleDebugSheetOpens(debugBuild: true, hasExtension: false))
    XCTAssertFalse(useSmileIDSampleDebugSheetOpens(debugBuild: false, hasExtension: false))
  }
}
