/// Where a relinked run picks up: its first step, or straight back into the SDK.
public enum UseSmileIDSampleResumePoint: String, Equatable, Sendable {
  /// Sent from a product tap: the new token's bindings decide which forms come first.
  case firstStep
  /// Sent from the SDK-entry gate: the forms are already filled.
  case flow
}

/// A run a gate sent to the scanner, with its presentation; held on the app state rather than in a route argument, which keeps it out of the route table.
public struct UseSmileIDSampleRunIntent: Equatable, Sendable {
  public let productId: String
  public let route: UseSmileIDSampleFlowRoute
  public let resumeAt: UseSmileIDSampleResumePoint

  public init(productId: String, route: UseSmileIDSampleFlowRoute, resumeAt: UseSmileIDSampleResumePoint = .flow) {
    self.productId = productId
    self.route = route
    self.resumeAt = resumeAt
  }
}
