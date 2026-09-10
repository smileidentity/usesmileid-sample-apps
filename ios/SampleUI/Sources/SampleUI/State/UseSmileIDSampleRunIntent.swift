/// A run the expiry gate sent away, with its presentation; held on the app state rather than in a route argument, which keeps it out of the route table.
public struct UseSmileIDSampleRunIntent: Equatable, Sendable {
  public let productId: String
  public let route: UseSmileIDSampleFlowRoute

  public init(productId: String, route: UseSmileIDSampleFlowRoute) {
    self.productId = productId
    self.route = route
  }
}
