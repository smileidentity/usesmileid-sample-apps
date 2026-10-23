@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleShellExtensionTest: XCTestCase {
  func testARegistryBuildHasNoExtension() throws {
    let sourceMode = Bundle.main.object(forInfoDictionaryKey: "UseSmileIDSampleSourceMode") as? String == "YES"
    try XCTSkipIf(sourceMode, "a source build carries its SDK repo's extension")
    XCTAssertNil(useSmileIDSampleShellExtension)
  }

  func testTheExtensionsLeadingRowsComeBeforeNetworkLogsAndItsOthersAfter() {
    XCTAssertEqual(UseSmileIDSampleDebugRowGroup.allCases, [.extensionLeading, .shell, .extension])
  }
}
