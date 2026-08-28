import SampleUI

/// Every pushable destination in `spec/routes.json`. Sheets are absent by design — see `Sheet`.
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

/// The tab a route belongs to, so a link lands in the right stack rather than the selected one.
extension Route {
  var tab: UseSmileIDSampleTab {
    switch self {
    case .verifications, .verificationDetails: .verifications
    case .settings, .licenses, .profiles, .profileConfig: .settings
    case .products, .consentDetailsForm, .idDetailsForm, .sdkFlow, .scanToken: .products
    }
  }

  /// Routes above the tab root; the root itself is never here, or the stack would draw it twice.
  var parents: [Route] {
    switch self {
    case .profileConfig: [.profiles]
    default: []
    }
  }
}
