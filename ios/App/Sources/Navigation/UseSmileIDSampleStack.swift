import SwiftUI

/// One tab's stack. `NavigationView` plus an `isActive` chain, the idiom the iOS 15 floor allows.
struct UseSmileIDSampleStack: View {
  let tab: UseSmileIDSampleTab

  var body: some View {
    NavigationView {
      UseSmileIDSampleStackLevel(tab: tab, depth: 0, route: tab.route)
    }
    .navigationViewStyle(.stack)
  }
}

/// Renders the route at this level and hosts the link to the one below.
private struct UseSmileIDSampleStackLevel: View {
  let tab: UseSmileIDSampleTab
  let depth: Int
  let route: Route
  @EnvironmentObject private var router: UseSmileIDSampleRouter

  var body: some View {
    UseSmileIDSampleDestination(route: route)
      .background(
        NavigationLink(isActive: router.isActive(tab, depth: depth)) {
          // Erased: a view whose body contains itself has no inferable body type.
          if let next = router.route(tab, depth: depth) {
            AnyView(UseSmileIDSampleStackLevel(tab: tab, depth: depth + 1, route: next))
          }
        } label: {
          EmptyView()
        }
        .hidden()
      )
  }
}
