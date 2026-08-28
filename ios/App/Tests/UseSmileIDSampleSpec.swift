import Foundation
import XCTest

/// Reads `spec/` from the source tree rather than a copied resource: the contract is the file, and a
/// copy is exactly the transcription `spec/README.md` forbids.
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
