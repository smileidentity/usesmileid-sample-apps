import SampleUI
import SwiftUI

/// The three tab roots — the only routes `spec/routes.json` gives `presentation: tab`.
enum UseSmileIDSampleTab: String, CaseIterable, Codable {
  case products
  case verifications
  case settings

  var route: Route {
    switch self {
    case .products: .products
    case .verifications: .verifications
    case .settings: .settings
    }
  }

  var title: String {
    switch self {
    case .products: "Products"
    case .verifications: "Verifications"
    case .settings: "Settings"
    }
  }

  var testId: String {
    switch self {
    case .products: UseSmileIDSampleTestIds.navProducts
    case .verifications: UseSmileIDSampleTestIds.navVerifications
    case .settings: UseSmileIDSampleTestIds.navSettings
    }
  }
}
