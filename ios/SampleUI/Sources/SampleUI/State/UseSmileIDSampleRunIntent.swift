/// A run the expiry gate sent away, carrying the presentation it was launched in (R3).
///
/// Held on the app state rather than in a route argument, which is what keeps continuation state out
/// of the four-platform route table (`navigation-plan.md` §8.3). The Compose twin's `saved`/`of` pair
/// has no counterpart: it exists so Android can hold this in `rememberSaveable`, and on iOS the run
/// is app state that ends with the process.
public struct UseSmileIDSampleRunIntent: Equatable, Sendable {
  public let productId: String
  public let route: UseSmileIDSampleFlowRoute

  public init(productId: String, route: UseSmileIDSampleFlowRoute) {
    self.productId = productId
    self.route = route
  }
}
