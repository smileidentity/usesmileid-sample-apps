import Foundation
import XCTest

/// The `spec/` directory, resolved from this file so the tests read the contract they sit beside.
enum UseSmileIDSampleSpecFiles {
  static var directory: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // SampleUITests
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // SampleUI
      .deletingLastPathComponent() // ios
      .deletingLastPathComponent() // the repo root
      .appendingPathComponent("spec")
  }

  static func object(_ name: String) throws -> [String: Any] {
    let data = try Data(contentsOf: directory.appendingPathComponent(name))
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], "spec/\(name) is not a JSON object")
  }
}
