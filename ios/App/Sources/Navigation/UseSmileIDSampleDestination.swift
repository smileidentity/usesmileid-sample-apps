import SampleUI
import SwiftUI

/// Binds a route to its screen; the mapping is the shell's because only it knows the route table.
struct UseSmileIDSampleDestination: View {
  let route: Route

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState

  var body: some View {
    switch route {
    case .products:
      ProductsScreen(
        state: .init(
          initials: app.initials,
          avatarColor: app.avatarColor,
          sessionId: app.sessionId,
          sessionRemaining: app.sessionRemaining,
          sessionEnded: app.sessionEnded
        ),
        onProduct: { product in router.open(.consentDetailsForm(productId: product.id)) },
        onProfile: { router.sheet = .profileSwitch },
        onScan: { router.open(.scanToken) }
      )
    case .verifications:
      VerificationsScreen()
    case .settings:
      SettingsScreen(
        state: .init(
          settings: app.settings,
          organisation: app.organisation,
          initials: app.initials,
          versionLabel: app.versionLabel,
          avatarColor: app.avatarColor
        ),
        onSettingChange: { setting, enabled in app.change(setting, to: enabled) },
        onProfile: { router.open(.profiles) },
        onNavRow: { row in open(row) },
        onOpenScenarioDrawer: { router.sheet = .scenarioDrawer },
        onSignOut: {}
      )
    default:
      UseSmileIDSampleSeat(name: String(describing: route))
    }
  }

  /// A row with no url is the app's own screen; the two legal pages leave the app deliberately.
  private func open(_ row: UseSmileIDSampleNavRow) {
    guard let url = row.url else {
      router.open(.licenses)
      return
    }
    UIApplication.shared.open(url)
  }
}

/// A named seat for a screen U3 has not built yet.
struct UseSmileIDSampleSeat: View {
  let name: String

  var body: some View {
    Text(name)
  }
}
