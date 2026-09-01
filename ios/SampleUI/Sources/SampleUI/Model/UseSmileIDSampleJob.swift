import Foundation

/// One submitted verification. `createdAt` is absolute, so grouping never depends on when it is read.
public struct UseSmileIDSampleJob: Equatable, Sendable {
  public let id: String
  public let userId: String
  public let product: UseSmileIDSampleProduct
  public let status: UseSmileIDSampleStatus
  public let createdAt: Date
  public let message: String
  /// The response code, not its display text: the reason phrase is composed where the row is drawn.
  public let httpStatus: Int?
  /// The environment at submission time: a row outlives the toggle that produced it.
  public let sandbox: Bool
  /// Nil on a fixture token.
  public let sessionId: String?
  /// A later session's refresh matches on this, not on the session.
  public let partnerId: String?

  public init(
    id: String,
    userId: String,
    product: UseSmileIDSampleProduct,
    status: UseSmileIDSampleStatus,
    createdAt: Date,
    message: String,
    httpStatus: Int?,
    sandbox: Bool = true,
    sessionId: String? = nil,
    partnerId: String? = nil
  ) {
    self.id = id
    self.userId = userId
    self.product = product
    self.status = status
    self.createdAt = createdAt
    self.message = message
    self.httpStatus = httpStatus
    self.sandbox = sandbox
    self.sessionId = sessionId
    self.partnerId = partnerId
  }

  /// Truncated for the row; the full value stays copyable.
  public var shortId: String {
    Self.shortened(id)
  }

  public var shortUserId: String {
    Self.shortened(userId)
  }

  private static let shortIdLength = 8

  private static func shortened(_ value: String) -> String {
    value.count <= shortIdLength ? value : value.prefix(shortIdLength) + "\u{2026}"
  }
}
