@testable import SampleUI
import XCTest

/// The second direction of the id contract.
///
/// `UseSmileIDSampleSpecTest` proves every declared id exists in `spec/test-ids.json`. Nothing
/// proved any of them reaches a view, and that gap has already shipped twice — `sample_selection_bar`
/// was declared and unapplied, and four list ids sat unused behind component parameters. A device
/// flow waiting on one of those times out with no clue why, so the unused ones are listed here
/// deliberately and the list shrinks as screens land.
final class UseSmileIDSampleTestIdUsageTest: XCTestCase {
  /// Ids not yet on a view. Delete an entry when its screen lands — a stale list fails the test
  /// below, so this cannot rot into a permanent excuse.
  ///
  /// The prefixes are anchors the real ids are built from; the other four wait on the
  /// verifications screen.
  private static let notYetApplied: Set<String> = [
    "productCardPrefix", "settingNavPrefix", "detailFieldPrefix", "detailCopyPrefix",
    "userDetailsFieldPrefix", "countryOptionPrefix", "idTypeOptionPrefix",
    "profileRowPrefix", "profileConfigFieldPrefix", "tokenEnvironmentPrefix",
    "scenarioItemPrefix", "themeItemPrefix",
    "jobRow", "jobRowStatus", "filterCount", "selectionCheckbox"
  ]

  func testEveryDeclaredIdIsAppliedSomewhere() throws {
    let sources = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Sources/SampleUI")
    let declarations = try String(contentsOf: sources.appendingPathComponent("UseSmileIDSampleTestIds.swift"))
    let declared = Self.names(in: declarations)
    XCTAssertFalse(declared.isEmpty, "parsed no id declarations")

    let body = try Self.swiftFiles(under: sources)
      .filter { $0.lastPathComponent != "UseSmileIDSampleTestIds.swift" }
      .map { try String(contentsOf: $0) }
      .joined()

    let unused = declared.filter { !body.contains(".\($0)") }.sorted()
    XCTAssertEqual(
      Set(unused), Self.notYetApplied,
      "the unused-id list is stale: remove ids now applied, add ids newly declared"
    )
  }

  private static func names(in source: String) -> Set<String> {
    let pattern = try! NSRegularExpression(pattern: #"static let (\w+) = "sample_"#)
    let range = NSRange(source.startIndex..<source.endIndex, in: source)
    return Set(pattern.matches(in: source, range: range).compactMap {
      Range($0.range(at: 1), in: source).map { String(source[$0]) }
    })
  }

  private static func swiftFiles(under directory: URL) throws -> [URL] {
    let all = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
    return (all?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
  }
}
