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

/// Where the run's ID details come from, which decides what fixing them means.
enum UseSmileIDSampleIdDetailsSource {
  /// The ID form, which the run asks for.
  case form
  /// The token, which only a new token can change.
  case token
  /// Nowhere: the product takes no ID details.
  case none
}

/// The move `action` makes for the run of `product`, gated as a product tap is: a live session, on the run's own partner.
func useSmileIDSampleErrorMove(
  _ action: UseSmileIDSampleErrorAction,
  product: UseSmileIDSampleProduct?,
  sessionLive: Bool,
  livePartnerId: String?,
  runPartnerId: String?,
  idDetails: UseSmileIDSampleIdDetailsSource
) -> UseSmileIDSampleErrorMove {
  guard let product else { return .leave }
  let ownPartner = runPartnerId != nil && runPartnerId == livePartnerId
  switch action {
  case .retry, .retryLater, .recapture:
    if !sessionLive {
      return .newToken(product, resumeAt: .flow)
    }
    return ownPartner ? .runAgain(product) : .runFromStart(product)
  case .fixInput:
    if !sessionLive || idDetails == .token {
      return .newToken(product, resumeAt: .firstStep)
    }
    return ownPartner && idDetails == .form ? .editIdDetails(product) : .runFromStart(product)
  case .newSession:
    return .newToken(product, resumeAt: .flow)
  case .exit:
    return .leave
  }
}
