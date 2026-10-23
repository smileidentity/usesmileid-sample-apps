import Njia
@testable import UseSmileIDSample
import XCTest

/// Reads `spec/njia-graph.json` with the app's own kinds and facts, as the shell will.
final class UseSmileIDSampleNjiaGraphTest: XCTestCase {
  func testTheGraphIsValid() throws {
    XCTAssertEqual(try UseSmileIDSampleNjiaSpec.graph().validate(), [])
  }

  func testEveryKindTheAppNamesIsAStepInTheGraphOnce() throws {
    let kinds = try UseSmileIDSampleNjiaSpec.graph().steps.map(\.kind)
    XCTAssertEqual(kinds.sorted { $0.order < $1.order }, UseSmileIDSampleStep.allCases)
  }

  func testEveryFactTheAppNamesIsOneASkipWhenReads() throws {
    let graph = try UseSmileIDSampleNjiaSpec.graph()
    let conditions = graph.nodes.compactMap(\.skipWhen) + graph.steps.compactMap(\.skipWhen)
    XCTAssertEqual(Set(conditions.flatMap { $0.allOf + $0.noneOf }), Set(UseSmileIDSampleFact.allCases))
  }

  func testTheBuildBundlesTheSpecGraph() throws {
    XCTAssertEqual(Bundle.main.useSmileIDSampleNjiaGraph(), try UseSmileIDSampleNjiaSpec.graph())
  }
}

/// The spec's graph, read from the repository rather than the bundle, so a stale bundle can't pass.
enum UseSmileIDSampleNjiaSpec {
  static func graph() throws -> UseSmileIDSampleGraph {
    let url = UseSmileIDSampleSpec.directory.appendingPathComponent(useSmileIDSampleNjiaGraphFile)
    return try useSmileIDSampleNjiaCodec.decodeGraph(String(contentsOf: url, encoding: .utf8))
  }
}

private extension UseSmileIDSampleStep {
  /// The case's place in the enum, to compare against the graph's order-free kinds.
  var order: Int {
    Self.allCases.firstIndex(of: self) ?? 0
  }
}
