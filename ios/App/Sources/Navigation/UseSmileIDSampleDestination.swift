import SampleUI
import SwiftUI

/// Binds a route to the screen that renders it. Screens live in `SampleUI`; this mapping is the
/// shell's, because only the shell knows the route table.
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

/// A named seat for a screen U3 has not built yet, so N1 is routable end to end before they exist.
struct UseSmileIDSampleSeat: View {
  let name: String

  var body: some View {
    Text(name)
  }
}
