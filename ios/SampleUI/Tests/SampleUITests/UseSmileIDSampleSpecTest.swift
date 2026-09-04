import Foundation
@testable import SampleUI
import XCTest

final class UseSmileIDSampleSpecTest: XCTestCase {
  private var specIds: Set<String> = []

  private var testIds: [String: Any] = [:]

  override func setUpWithError() throws {
    testIds = try UseSmileIDSampleSpecFiles.object("test-ids.json")
    specIds = Self.ids(in: testIds)
    XCTAssertFalse(specIds.isEmpty, "extracted no ids from spec/test-ids.json")
  }

  func testEveryDeclaredTestIdIsInTheSpec() {
    for id in UseSmileIDSampleTestIds.all {
      XCTAssertTrue(specIds.contains(id), "\(id) is not in spec/test-ids.json")
    }
  }

  /// The card's group in the spec is the card plus one id per field; the declared set is the same set.
  func testTheResultCardIdsAreExactlyTheSpecsResultCardGroup() throws {
    let groups = try XCTUnwrap(testIds["ids"] as? [String: Any])
    let group = try XCTUnwrap(groups["resultCard"] as? [[String: Any]])
    let expected = Set(group.compactMap { $0["id"] as? String })
    XCTAssertFalse(expected.isEmpty, "extracted no resultCard ids")
    XCTAssertEqual(Set(UseSmileIDSampleTestIds.all.filter { $0.hasPrefix("sample_result_") }), expected)
  }

  func testFlowScenariosMatchTheSpec() throws {
    XCTAssertEqual(try scenarioIds(kind: "flow"), UseSmileIDSampleScenario.allCases.map(\.id))
  }

  func testThemeScenariosMatchTheSpec() throws {
    XCTAssertEqual(try scenarioIds(kind: "theme"), UseSmileIDSampleThemeScenario.allCases.map(\.id))
  }

  /// In spec order, so the drawer lists them as the other three apps do.
  private func scenarioIds(kind: String) throws -> [String] {
    let spec = try UseSmileIDSampleSpecFiles.object("scenarios.json")
    let scenarios = try XCTUnwrap(spec["scenarios"] as? [[String: Any]])
    let ids = scenarios.filter { $0["kind"] as? String == kind }.compactMap { $0["id"] as? String }
    XCTAssertFalse(ids.isEmpty, "extracted no \(kind) scenarios")
    return ids
  }

  func testTheFlowRouteIdsAreTheirCaseNames() {
    for route in UseSmileIDSampleFlowRoute.allCases {
      XCTAssertEqual(route.id, "\(route)")
    }
  }

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
