@testable import SampleUI
import XCTest

/// The other direction of the id contract: this proves a declared id reaches a view, not just the spec.
final class UseSmileIDSampleTestIdUsageTest: XCTestCase {
  /// Ids not yet on a view; delete an entry when its screen lands, because a stale list fails.
  private static let notYetApplied: Set<String> = [
    "productCardPrefix", "settingNavPrefix", "detailFieldPrefix", "detailCopyPrefix",
    "userDetailsFieldPrefix", "countryOptionPrefix", "idTypeOptionPrefix",
    "profileRowPrefix", "profileConfigFieldPrefix", "tokenEnvironmentPrefix",
    "scenarioItemPrefix", "themeItemPrefix",
    "jobRowPrefix", "filterChipPrefix", "filterCountPrefix", "selectionCheckboxPrefix",
    "licenseRowPrefix", "licenseTextPrefix", "licenseLinkPrefix"
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

    // Qualified, not `.name`: the colour token `colors.filterChip` matched the loose form for months.
    let unused = declared.filter { !body.contains("UseSmileIDSampleTestIds.\($0)") }.sorted()
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
