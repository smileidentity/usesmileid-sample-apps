import SampleUI
import SwiftUI

/// Binds a route to its screen; the mapping is the shell's because only it knows the route table.
struct UseSmileIDSampleDestination: View {
  let route: Route

  var body: some View {
    switch route {
    case .products: ProductsScreen()
    case .verifications: VerificationsScreen()
    case .settings: SettingsScreen()
    default: UseSmileIDSampleSeat(name: String(describing: route))
    }
  }
}

/// A named seat for a screen U3 has not built yet.
struct UseSmileIDSampleSeat: View {
  let name: String

  var body: some View {
    Text(name)
  }
}
