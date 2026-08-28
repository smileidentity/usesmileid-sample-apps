import SampleUI

/// Every pushable destination in `spec/routes.json`. `Codable` is what makes restoration a decode
/// rather than bespoke logic — the whole path round-trips through `@SceneStorage`.
///
/// Sheets are deliberately absent: a sheet is a layer over the screen that owns it, never a
/// destination that replaces it. See `Sheet`.
enum Route: Hashable, Codable {
  case products
  case verifications
  case settings
  case licenses
  case verificationDetails(jobId: String)
  case consentDetailsForm(productId: String)
  case idDetailsForm(productId: String)
  case sdkFlow(productId: String, presentation: UseSmileIDSampleFlowRoute)
  case profiles
  case profileConfig(profileId: String)
  case scanToken
}

/// The tab a route belongs to, so a deep link lands in the right stack rather than the selected one.
extension Route {
  var tab: UseSmileIDSampleTab {
    switch self {
    case .verifications, .verificationDetails: .verifications
    case .settings, .licenses, .profiles, .profileConfig: .settings
    case .products, .consentDetailsForm, .idDetailsForm, .sdkFlow, .scanToken: .products
    }
  }

  /// The routes pushed above the tab root before this one, so Back works after a cold link into a
  /// detail. The tab root is never in here — the stack draws it, so listing it would render it twice.
  var parents: [Route] {
    switch self {
    case .profileConfig: [.profiles]
    default: []
    }
  }
}
