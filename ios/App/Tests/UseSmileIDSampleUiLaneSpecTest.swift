import Foundation
import XCTest

/// The workflow names one class per job, so a class added without one would never run while the lane stayed green.
final class UseSmileIDSampleUiLaneSpecTest: XCTestCase {
  func testTheWorkflowRunsEveryUiTestClass() throws {
    let onDisk = try Self.classesOnDisk()
    XCTAssertFalse(onDisk.isEmpty, "found no UI test classes to check the workflow against")
    XCTAssertEqual(
      try Self.classesInWorkflow(Self.workflow()),
      onDisk,
      "the workflow's matrix and ios/App/UITests have drifted: a class with no job never runs"
    )
  }

  /// The phase names the script accepts, so a matrix entry cannot ask it for something it rejects.
  func testTheWorkflowOnlyAsksForPhasesTheScriptKnows() throws {
    let phases = try Set(Self.matches(#"phase:\s*(\w+)"#, in: Self.workflow()))
    XCTAssertFalse(phases.isEmpty, "parsed no phases from the workflow")
    XCTAssertTrue(phases.isSubset(of: ["checks", "ui"]), "the workflow asks for \(phases)")
  }

  private static func workflow() throws -> String {
    try String(contentsOf: repoRoot.appendingPathComponent(".github/workflows/ios.yml"), encoding: .utf8)
  }

  private static func classesInWorkflow(_ yaml: String) -> Set<String> {
    Set(matches(#"class:\s*(\w+)"#, in: yaml))
  }

  private static func classesOnDisk() throws -> Set<String> {
    let directory = repoRoot.appendingPathComponent("ios/App/UITests")
    let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    let sources = try files.filter { $0.pathExtension == "swift" }
      .map { try String(contentsOf: $0, encoding: .utf8) }
      .joined(separator: "\n")
    return Set(matches(#"final class (\w+): XCTestCase"#, in: sources))
  }

  private static func matches(_ pattern: String, in body: String) -> [String] {
    let expression = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(body.startIndex..<body.endIndex, in: body)
    return expression.matches(in: body, range: range).compactMap {
      Range($0.range(at: 1), in: body).map { String(body[$0]) }
    }
  }

  private static var repoRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // App
      .deletingLastPathComponent() // ios
      .deletingLastPathComponent() // the repo root
  }
}
