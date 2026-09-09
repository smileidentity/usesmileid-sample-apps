import Foundation
import SwiftData

/// One submitted verification in the store, keyed by job id.
///
/// The same shape as the Android row, so the two read the same, and the same shape as the JSON
/// document this replaced, so the import in ``UseSmileIDSampleJobImport`` is a field-for-field copy.
@Model
final class UseSmileIDSampleJobEntity {
  /// Not `@Attribute(.unique)`: a unique attribute upserts, and `add` has to ignore an id it already
  /// holds so a repeated result delivery cannot overwrite the row it already wrote.
  var id: String = ""
  var userId: String = ""
  var productId: String = ""
  var statusId: String = ""
  var createdAtMillis: Int64 = 0
  var message: String = ""
  var httpStatus: Int?
  var sandbox: Bool = true
  var sessionId: String?
  var partnerId: String?
  var boundUserDetails: Bool = false
  var boundIdDetails: Bool = false
  var boundConsent: Bool = false

  init(_ record: UseSmileIDSampleJobRecord) {
    apply(record)
  }

  /// Every field, so a caller cannot half-update a row and leave it internally inconsistent.
  func apply(_ record: UseSmileIDSampleJobRecord) {
    id = record.id
    userId = record.userId
    productId = record.productId
    statusId = record.statusId
    createdAtMillis = record.createdAtMillis
    message = record.message
    httpStatus = record.httpStatus
    sandbox = record.sandbox
    sessionId = record.sessionId
    partnerId = record.partnerId
    boundUserDetails = record.boundUserDetails
    boundIdDetails = record.boundIdDetails
    boundConsent = record.boundConsent
  }

  var record: UseSmileIDSampleJobRecord {
    UseSmileIDSampleJobRecord(
      id: id,
      userId: userId,
      productId: productId,
      statusId: statusId,
      createdAtMillis: createdAtMillis,
      message: message,
      httpStatus: httpStatus,
      sandbox: sandbox,
      sessionId: sessionId,
      partnerId: partnerId,
      boundUserDetails: boundUserDetails,
      boundIdDetails: boundIdDetails,
      boundConsent: boundConsent
    )
  }
}

/// The schema, versioned explicitly rather than left implicit.
///
/// SwiftData does not enforce a migration the way Room does — `VersionedSchema` is ordinary code and
/// nothing fails to build if a property is added without one. So the guarantee is a test per version
/// that loads a store written under it; see `UseSmileIDSampleJobSchemaTest`.
enum UseSmileIDSampleJobSchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version {
    Schema.Version(1, 0, 0)
  }

  static var models: [any PersistentModel.Type] {
    [UseSmileIDSampleJobEntity.self]
  }
}

enum UseSmileIDSampleJobMigrations: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [UseSmileIDSampleJobSchemaV1.self]
  }

  static var stages: [MigrationStage] {
    []
  }
}

extension ModelContainer {
  /// The app's store. One file, named so the import can tell a fresh install from an upgrade.
  static func useSmileIDSampleJobs(inMemory: Bool = false) throws -> ModelContainer {
    try ModelContainer(
      for: UseSmileIDSampleJobEntity.self,
      migrationPlan: UseSmileIDSampleJobMigrations.self,
      configurations: ModelConfiguration(
        "UseSmileIDSampleJobs",
        schema: Schema(versionedSchema: UseSmileIDSampleJobSchemaV1.self),
        isStoredInMemoryOnly: inMemory
      )
    )
  }
}
