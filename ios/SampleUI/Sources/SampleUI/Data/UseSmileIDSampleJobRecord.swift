import Foundation

/// One verification on disk, keyed by job id: enums as string ids, never ordinals, and the instant as epoch millis.
struct UseSmileIDSampleJobRecord: Codable, Equatable, Sendable {
  var id: String
  var userId: String
  var productId: String
  var statusId: String
  var createdAtMillis: Int64
  var message: String
  /// The response code the row was last written from; nil when nothing has answered for it yet.
  var httpStatus: Int?
  /// Sandbox or production at submission time. A row outlives the toggle that produced it.
  var sandbox: Bool
  /// The session the run submitted under; nil on a fixture token, which has no status to ask for.
  var sessionId: String?
  /// The partner the run submitted under; a refresh matches this, not the session.
  var partnerId: String?
  /// Which fields the token supplied — the shape, never the values: one of them is a vault reference.
  var boundUserDetails = false
  var boundIdDetails = false
  var boundConsent = false
}

extension UseSmileIDSampleJobRecord {
  /// Key by key because synthesis ignores a default value, and one undecodable row is every row.
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    userId = try values.decode(String.self, forKey: .userId)
    productId = try values.decode(String.self, forKey: .productId)
    statusId = try values.decode(String.self, forKey: .statusId)
    createdAtMillis = try values.decode(Int64.self, forKey: .createdAtMillis)
    message = try values.decode(String.self, forKey: .message)
    httpStatus = try values.decodeIfPresent(Int.self, forKey: .httpStatus)
    sandbox = try values.decode(Bool.self, forKey: .sandbox)
    sessionId = try values.decodeIfPresent(String.self, forKey: .sessionId)
    partnerId = try values.decodeIfPresent(String.self, forKey: .partnerId)
    boundUserDetails = try values.decodeIfPresent(Bool.self, forKey: .boundUserDetails) ?? false
    boundIdDetails = try values.decodeIfPresent(Bool.self, forKey: .boundIdDetails) ?? false
    boundConsent = try values.decodeIfPresent(Bool.self, forKey: .boundConsent) ?? false
  }

  init(
    job: UseSmileIDSampleJob,
    boundUserDetails: Bool = false,
    boundIdDetails: Bool = false,
    boundConsent: Bool = false
  ) {
    self.init(
      id: job.id,
      userId: job.userId,
      productId: job.product.id,
      statusId: job.status.rawValue,
      createdAtMillis: Int64((job.createdAt.timeIntervalSince1970 * 1000).rounded()),
      message: job.message,
      httpStatus: job.httpStatus,
      sandbox: job.sandbox,
      sessionId: job.sessionId,
      partnerId: job.partnerId,
      boundUserDetails: boundUserDetails,
      boundIdDetails: boundIdDetails,
      boundConsent: boundConsent
    )
  }

  /// Unknown ids fall back rather than throwing: a rename must not crash a restore.
  var job: UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: id,
      userId: userId,
      product: UseSmileIDSampleProduct(rawValue: productId) ?? UseSmileIDSampleProduct.allCases[0],
      status: UseSmileIDSampleStatus(rawValue: statusId) ?? .processing,
      createdAt: Date(timeIntervalSince1970: Double(createdAtMillis) / 1000),
      message: message,
      httpStatus: httpStatus,
      sandbox: sandbox,
      sessionId: sessionId,
      partnerId: partnerId
    )
  }
}

/// The file's whole contents. Versioned, so a later shape can be read forward rather than guessed at.
struct UseSmileIDSampleJobFile: Codable, Sendable {
  var version = UseSmileIDSampleJobFile.currentVersion
  var jobs: [UseSmileIDSampleJobRecord]

  static let currentVersion = 1
}
