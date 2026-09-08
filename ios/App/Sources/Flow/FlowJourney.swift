import SampleUI

extension UseSmileIDSampleAppState {
  /// Where a product starts: a form is skipped only when the token already carries all of it.
  func firstStep(for product: UseSmileIDSampleProduct) -> Route {
    tokenBindsUserDetails
      ? stepAfterUserDetails(product)
      : .consentDetailsForm(productId: product.id)
  }

  /// What follows user details, shared with that form's own Continue so the two routes cannot drift.
  func stepAfterUserDetails(_ product: UseSmileIDSampleProduct) -> Route {
    product.needsIdDetails && !tokenBindsIdDetails(product)
      ? .idDetailsForm(productId: product.id)
      : sdkFlow(product)
  }

  /// The wizard's last hop, carrying the launched presentation (R3). Without it the in-shell route is
  /// unreachable with a payload: its other carriers are cold starts, where the forms are always empty.
  func sdkFlow(_ product: UseSmileIDSampleProduct) -> Route {
    .sdkFlow(productId: product.id, presentation: launchArguments.route)
  }
}
