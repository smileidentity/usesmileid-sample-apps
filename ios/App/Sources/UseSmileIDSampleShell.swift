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
      // At the root, over whichever route is showing; a link opens the owner first, so it layers.
      .sheet(item: $router.sheet) { sheet in
        sheetContent(sheet)
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

  @ViewBuilder
  private func sheetContent(_ sheet: Sheet) -> some View {
    switch sheet {
    case .countryPicker:
      CountryPickerSheet(
        selected: app.idDetails.country,
        query: $app.countryQuery,
        onSelect: { app.selectCountry($0)
          router.sheet = nil }
      )
    case .idTypePicker:
      IdTypePickerSheet(
        country: app.idDetails.country,
        selected: app.idDetails.idType,
        query: $app.idTypeQuery,
        onSelect: { app.idDetails.idType = $0
          router.sheet = nil }
      )
    default:
      UseSmileIDSampleSeat(name: sheet.rawValue)
    }
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
