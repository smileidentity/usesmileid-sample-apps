import Foundation
@testable import SampleUI
import SwiftData
import XCTest

/// The guarantee Room gives Android by failing the build, which SwiftData does not give: a store
/// written under a released schema still loads. One case per version, added when a version is.
final class UseSmileIDSampleJobSchemaTest: XCTestCase {
  private var directory: URL!

  override func setUpWithError() throws {
    directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("schema-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: directory)
  }

  func testAStoreWrittenUnderVersionOneStillLoads() throws {
    let url = directory.appendingPathComponent("jobs.store")
    try write(Self.row, to: url)

    let reopened = try container(at: url)
    let rows = try ModelContext(reopened).fetch(FetchDescriptor<UseSmileIDSampleJobEntity>())
    XCTAssertEqual(rows.map(\.id), ["job-1"])
    let record = try XCTUnwrap(rows.first).record
    XCTAssertEqual(record, Self.row, "a row round-tripped through the released schema came back changed")
  }

  /// The version the migration plan declares is the one the app writes, so a stage added without
  /// bumping it would migrate nothing.
  func testTheDeclaredVersionIsTheOneTheMigrationPlanStartsFrom() {
    XCTAssertEqual(UseSmileIDSampleJobSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
    XCTAssertEqual(UseSmileIDSampleJobMigrations.schemas.count, 1)
    XCTAssertTrue(
      UseSmileIDSampleJobMigrations.schemas.first == UseSmileIDSampleJobSchemaV1.self,
      "the plan no longer starts at the schema this test pins"
    )
  }

  /// Nil is a column that has never been written, which is not the same as a zero or an empty string.
  func testTheOptionalColumnsSurviveBeingAbsent() throws {
    let url = directory.appendingPathComponent("sparse.store")
    var sparse = Self.row
    sparse.httpStatus = nil
    sparse.sessionId = nil
    sparse.partnerId = nil
    try write(sparse, to: url)

    let rows = try ModelContext(container(at: url)).fetch(FetchDescriptor<UseSmileIDSampleJobEntity>())
    let record = try XCTUnwrap(rows.first).record
    XCTAssertNil(record.httpStatus)
    XCTAssertNil(record.sessionId)
    XCTAssertNil(record.partnerId)
  }

  private func container(at url: URL) throws -> ModelContainer {
    try ModelContainer(
      for: UseSmileIDSampleJobEntity.self,
      migrationPlan: UseSmileIDSampleJobMigrations.self,
      configurations: ModelConfiguration(
        schema: Schema(versionedSchema: UseSmileIDSampleJobSchemaV1.self),
        url: url
      )
    )
  }

  private func write(_ record: UseSmileIDSampleJobRecord, to url: URL) throws {
    let context = try ModelContext(container(at: url))
    context.insert(UseSmileIDSampleJobEntity(record))
    try context.save()
  }

  private static let row = UseSmileIDSampleJobRecord(
    id: "job-1",
    userId: "user-1",
    productId: "documentVerification",
    statusId: "Clear",
    createdAtMillis: 1784202612000,
    message: "Approved",
    httpStatus: 200,
    sandbox: true,
    sessionId: "session-1",
    partnerId: "partner-1",
    boundUserDetails: true,
    boundIdDetails: false,
    boundConsent: true
  )
}
