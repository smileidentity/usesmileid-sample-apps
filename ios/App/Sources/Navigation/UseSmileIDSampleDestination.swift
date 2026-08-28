import SampleUI
import SwiftUI

/// Binds a route to its screen; the mapping is the shell's because only it knows the route table.
struct UseSmileIDSampleDestination: View {
  let route: Route

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var inAppLink: UseSmileIDSampleInAppLink?

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
      browser(SettingsScreen(
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
      ))
    default:
      UseSmileIDSampleSeat(name: String(describing: route))
    }
  }

  /// A layer over the screen that opened it, never a destination.
  private func browser(_ content: some View) -> some View {
    content.sheet(item: $inAppLink) { UseSmileIDSampleBrowser(url: $0.url) }
  }

  /// Three destinations, per `spec/screens.json` → linkPresentation: no url is the app's own
  /// screen; `opensInApp` stays in an in-app browser; the two legal pages eject, because both serve
  /// their document as an embedded PDF a mobile browser shows as a stub.
  private func open(_ row: UseSmileIDSampleNavRow) {
    guard let url = row.url else {
      router.open(.licenses)
      return
    }
    if row.opensInApp {
      inAppLink = UseSmileIDSampleInAppLink(url: url)
    } else {
      UIApplication.shared.open(url)
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
