import SampleUI

/// Where a failure's one action takes the user.
enum UseSmileIDSampleErrorMove: Equatable {
  /// The product's flow again, past the forms, as a new job.
  case runAgain(UseSmileIDSampleProduct)
  /// The product's first step under the live session, whose partner may not take the details the run had.
  case runFromStart(UseSmileIDSampleProduct)
  /// The ID form, whose Continue starts the flow.
  case editIdDetails(UseSmileIDSampleProduct)
  /// The scanner for a new token, then the run from `resumeAt`.
  case newToken(UseSmileIDSampleProduct, resumeAt: UseSmileIDSampleResumePoint)
  /// Out of the run, to the products tab.
  case leave
}

/// The move `action` makes for the run of `product`, gated as a product tap is: a live session, on the run's own partner.
func useSmileIDSampleErrorMove(
  _ action: UseSmileIDSampleErrorAction,
  product: UseSmileIDSampleProduct?,
  sessionLive: Bool,
  livePartnerId: String?,
  runPartnerId: String?
) -> UseSmileIDSampleErrorMove {
  guard let product else { return .leave }
  switch action {
  case .retry, .retryLater, .recapture:
    if !sessionLive { return .newToken(product, resumeAt: .flow) }
    if let runPartnerId, runPartnerId == livePartnerId { return .runAgain(product) }
    return .runFromStart(product)
  case .fixInput:
    return sessionLive ? .editIdDetails(product) : .newToken(product, resumeAt: .firstStep)
  case .newSession:
    return .newToken(product, resumeAt: .flow)
  case .exit:
    return .leave
  }
}
