import Foundation
@testable import SampleUI
import XCTest

/// The library's half of the spec validation: every id it declares must exist in `spec/test-ids.json`,
/// so a typo fails here rather than as a device flow that silently matches nothing.
final class UseSmileIDSampleSpecTest: XCTestCase {
  private var specIds: Set<String> = []

  override func setUpWithError() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // SampleUITests
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // SampleUI
      .deletingLastPathComponent() // ios
      .deletingLastPathComponent() // the repo root
      .appendingPathComponent("spec/test-ids.json")
    let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    specIds = Self.ids(in: json)
    XCTAssertFalse(specIds.isEmpty, "extracted no ids from spec/test-ids.json")
  }

  func testEveryDeclaredTestIdIsInTheSpec() {
    for id in UseSmileIDSampleTestIds.all {
      XCTAssertTrue(specIds.contains(id), "\(id) is not in spec/test-ids.json")
    }
  }

  func testTheFlowRouteIdsAreTheirCaseNames() {
    for route in UseSmileIDSampleFlowRoute.allCases {
      XCTAssertEqual(route.id, "\(route)")
    }
  }

  /// Every `sample_*` string anywhere in the file, so the shape of the spec can change without this.
  private static func ids(in json: Any) -> Set<String> {
    switch json {
    case let string as String:
      string.hasPrefix("sample_") ? [string] : []
    case let array as [Any]:
      array.reduce(into: Set<String>()) { $0.formUnion(ids(in: $1)) }
    case let object as [String: Any]:
      object.reduce(into: Set<String>()) { result, entry in
        if entry.key.hasPrefix("sample_") {
          result.insert(entry.key)
        }
        result.formUnion(ids(in: entry.value))
      }
    default:
      []
    }
  }
}
