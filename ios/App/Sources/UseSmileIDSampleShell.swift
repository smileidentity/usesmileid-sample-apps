import SampleUI
import SwiftUI

/// The window's root. Everything identity-bound stays here — `SampleUI` runs under eight identities.
struct UseSmileIDSampleShell: View {
  @StateObject private var router = UseSmileIDSampleRouter()
  @StateObject private var app = UseSmileIDSampleAppState()

  /// One value, so the tab and its stacks cannot restore out of step.
  @SceneStorage("navigation") private var storedNavigation: String = ""

  var body: some View {
    // One tab mounted at a time: a hidden stack still answers id queries, and neither
    // `accessibilityHidden` nor a children-ignore suppresses its UIKit-backed controls.
    UseSmileIDSampleStack(tab: router.selectedTab) { navBar }
      .environmentObject(router)
      .environmentObject(app)
      // Pinned both ways, not nil: following the system when the switch is off leaves a device in
      // dark mode rendering dark while Settings reads off.
      .preferredColorScheme(app.settings.darkMode ? .dark : .light)
      // Held here until U2/U3 land the screens that own these sheets.
      .sheet(item: $router.sheet) { sheet in
        UseSmileIDSampleSeat(name: sheet.rawValue)
      }
      .onOpenURL { url in
        guard let link = UseSmileIDSampleLinks.resolve(url) else { return }
        switch link {
        case .route(let route):
          router.open(route)
        case .sheet(let sheet, let owner):
          router.open(owner)
          router.sheet = sheet
        }
      }
      .onAppear { router.restore(from: storedNavigation) }
      .onChange(of: router.selectedTab) { _ in storedNavigation = router.encodedState() }
      .onChange(of: router.paths) { _ in storedNavigation = router.encodedState() }
  }

  /// The design's floating pill, ruled over `TabView`. Sits inside the host, so a push covers it —
  /// the visibility rule the Compose twin spells out as `selectedTab != null`.
  private var navBar: some View {
    UseSmileIDSampleNavBar(
      selected: router.selectedTab.navItem,
      // nil until `scanToken` starts a session; the ring is absent rather than reading empty.
      sessionProgress: nil,
      onSelect: { select(UseSmileIDSampleTab($0)) },
      onToken: { router.open(.scanToken) }
    )
  }

  /// Re-selecting the showing tab pops it to its root, as the platform does.
  private func select(_ tab: UseSmileIDSampleTab) {
    if tab == router.selectedTab {
      router.openTabRoot(tab)
    } else {
      router.selectedTab = tab
    }
  }
}
