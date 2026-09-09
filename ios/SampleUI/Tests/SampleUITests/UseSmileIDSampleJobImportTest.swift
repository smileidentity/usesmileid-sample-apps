import Foundation
@testable import SampleUI
import SwiftData
import XCTest

/// The upgrade path: rows a pre-SwiftData version left in a JSON document reach the new store, and
/// reach it once. This is the only code that can lose a partner's verification history.
final class UseSmileIDSampleJobImportTest: XCTestCase {
  private var url: URL!

  override func setUpWithError() throws {
    url = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("import-\(UUID().uuidString).json")
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: url)
  }

  func testTheDocumentsRowsReachTheStore() async throws {
    try write(Self.twoRows)
    let ids = await store().jobs.map(\.id)
    XCTAssertEqual(ids, ["job-2", "job-1"], "newest first, as the list orders them")
  }

  func testTheDocumentIsGoneOnceItsRowsAreIn() async throws {
    try write(Self.twoRows)
    _ = await store().jobs
    XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "a second launch would import again")
  }

  /// A crash between committing the rows and deleting the file repeats the import, so the insert
  /// ignoring an id it already holds is what makes that safe rather than duplicating.
  func testImportingTwiceOverTheSameContainerKeepsOneRowEach() async throws {
    let container = Self.container()
    try write(Self.twoRows)
    _ = await store(container).jobs

    try write(Self.twoRows)
    let ids = await store(container).jobs.map(\.id)
    XCTAssertEqual(ids, ["job-2", "job-1"])
  }

  func testAFreshInstallHasNothingToImportAndDoesNotFail() async {
    let ids = await store().jobs.map(\.id)
    XCTAssertEqual(ids, [])
  }

  /// The version is what the field was always for: an unknown one is left alone rather than guessed
  /// at, and leaves the document in place for a version that does know how to read it.
  func testADocumentFromAnUnknownVersionIsNotImportedAndIsNotDeleted() async throws {
    try write(#"{"version":99,"jobs":[\#(Self.row(id: "job-1", millis: 1))]}"#)
    let ids = await store().jobs.map(\.id)
    XCTAssertEqual(ids, [])
    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
  }

  /// A document that exists but cannot be read is not the same as no document. Reading it as "no
  /// rows" would let the caller delete it, losing rows a later launch could have imported.
  func testAnUnreadableDocumentIsLeftAloneRatherThanTreatedAsEmpty() async throws {
    // A directory at the document's path: it exists, and reading it as data fails — which is the
    // shape of a permissions or I/O failure without having to provoke one.
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    let ids = await store().jobs.map(\.id)
    XCTAssertEqual(ids, [])
    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "the document was consumed")
  }

  func testADocumentThatCannotBeDecodedImportsNothing() async throws {
    try write("not json")
    let ids = await store().jobs.map(\.id)
    XCTAssertEqual(ids, [])
  }

  private func write(_ json: String) throws {
    try Data(json.utf8).write(to: url)
  }

  private func store(_ container: ModelContainer? = nil) -> UseSmileIDSampleJobStore {
    UseSmileIDSampleJobStore(
      container: container ?? Self.container(),
      source: UseSmileIDSampleUnreachableStatusSource(),
      importingLegacyFileAt: url
    )
  }

  private static func container() -> ModelContainer {
    try! ModelContainer.useSmileIDSampleJobs(inMemory: true)
  }

  private static func row(id: String, millis: Int64) -> String {
    """
    {"id":"\(id)","userId":"user-1","productId":"documentVerification","statusId":"Clear",\
    "createdAtMillis":\(millis),"message":"Approved","sandbox":true}
    """
  }

  private static let twoRows = """
  {"version":1,"jobs":[\(row(id: "job-1", millis: 1000)),\(row(id: "job-2", millis: 2000))]}
  """
}
