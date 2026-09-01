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

  /// Switched rather than bridged by `rawValue`, so a destination added to one enum fails to build.
  var navItem: UseSmileIDSampleNavItem {
    switch self {
    case .products: .products
    case .verifications: .verifications
    case .settings: .settings
    }
  }

  init(_ item: UseSmileIDSampleNavItem) {
    switch item {
    case .products: self = .products
    case .verifications: self = .verifications
    case .settings: self = .settings
    }
  }
}
