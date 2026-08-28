import SampleUI
import SwiftUI

/// The window's root. Everything identity-bound stays here — `SampleUI` runs under eight identities.
struct UseSmileIDSampleShell: View {
  @StateObject private var router = UseSmileIDSampleRouter()

  /// One value, so the tab and its stacks cannot restore out of step.
  @SceneStorage("navigation") private var storedNavigation: String = ""

  var body: some View {
    TabView(selection: tabSelection) {
      ForEach(UseSmileIDSampleTab.allCases, id: \.self) { tab in
        UseSmileIDSampleStack(tab: tab)
          // On the label, never on the stack: an id on a container overrides every child id.
          .tabItem { Text(tab.title).accessibilityIdentifier(tab.testId) }
          .tag(tab)
      }
    }
    .environmentObject(router)
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

  /// Re-selecting the showing tab pops it to its root, as the platform does.
  private var tabSelection: Binding<UseSmileIDSampleTab> {
    Binding(
      get: { router.selectedTab },
      set: { tab in
        if tab == router.selectedTab {
          router.openTabRoot(tab)
        } else {
          router.selectedTab = tab
        }
      }
    )
  }
}
