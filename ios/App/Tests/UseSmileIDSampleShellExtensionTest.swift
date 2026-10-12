@testable import UseSmileIDSample
import XCTest

/// A registry build carries no extension, so the public app behaves exactly as it ships.
@MainActor
final class UseSmileIDSampleShellExtensionTest: XCTestCase {
  func testARegistryBuildHasNoExtension() {
    XCTAssertNil(useSmileIDSampleShellExtension)
  }
}
