import SampleUI

/// Where a failure's one action takes the user.
enum UseSmileIDSampleErrorMove: Equatable {
  /// The product's flow again, past the forms, as a new job.
  case runAgain(UseSmileIDSampleProduct)
  /// The ID form, whose Continue starts the flow.
  case editIdDetails(UseSmileIDSampleProduct)
  /// The scanner for a new token, then the flow.
  case newToken(UseSmileIDSampleProduct)
  /// Out of the run, to the products tab.
  case leave
}

/// The move `action` makes for the run of `product`; without a product there is nothing to run again.
func useSmileIDSampleErrorMove(_ action: UseSmileIDSampleErrorAction, product: UseSmileIDSampleProduct?) -> UseSmileIDSampleErrorMove {
  guard let product else { return .leave }
  switch action {
  case .retry, .retryLater, .recapture: return .runAgain(product)
  case .fixInput: return .editIdDetails(product)
  case .newSession: return .newToken(product)
  case .exit: return .leave
  }
}
