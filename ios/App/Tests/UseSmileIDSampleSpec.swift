import Foundation
import XCTest

enum UseSmileIDSampleSpec {
  static var directory: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // App
      .deletingLastPathComponent() // ios
      .deletingLastPathComponent() // the repo root
      .appendingPathComponent("spec")
  }

  static func object(_ name: String) throws -> [String: Any] {
    let url = directory.appendingPathComponent(name)
    let data = try Data(contentsOf: url)
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw NSError(domain: "spec", code: 1, userInfo: [NSLocalizedDescriptionKey: "spec/\(name) is not a JSON object"])
    }
    return object
  }
}
