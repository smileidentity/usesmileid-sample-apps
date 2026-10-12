@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleShellExtensionTest: XCTestCase {
  func testARegistryBuildHasNoExtension() {
    XCTAssertNil(useSmileIDSampleShellExtension)
  }
}
