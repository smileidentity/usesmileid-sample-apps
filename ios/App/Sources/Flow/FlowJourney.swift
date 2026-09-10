import SampleUI

extension UseSmileIDSampleAppState {
  /// A form is skipped only when the token already carries all of it.
  func firstStep(for product: UseSmileIDSampleProduct) -> Route {
    tokenBindsUserDetails
      ? stepAfterUserDetails(product)
      : .consentDetailsForm(productId: product.id)
  }

  /// Shared with the form's own Continue, so the two routes cannot drift.
  func stepAfterUserDetails(_ product: UseSmileIDSampleProduct) -> Route {
    product.needsIdDetails && !tokenBindsIdDetails(product)
      ? .idDetailsForm(productId: product.id)
      : sdkFlow(product)
  }

  /// Carries the launched presentation: without it the in-shell route is only reached by a cold link.
  func sdkFlow(_ product: UseSmileIDSampleProduct) -> Route {
    .sdkFlow(productId: product.id, presentation: launchArguments.route)
  }
}
