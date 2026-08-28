import SampleUI
import SwiftUI

/// The window's root: three tabs, each with its own stack, restored from scene storage and driven
/// by deep links. Everything identity-bound stays here — `SampleUI` runs under eight identities.
struct UseSmileIDSampleShell: View {
  @StateObject private var router = UseSmileIDSampleRouter()

  /// One encoded value rather than two, so the tab and its stacks can never restore out of step.
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

  /// Re-selecting the tab already showing pops it to its root, which is the platform's own behaviour.
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
