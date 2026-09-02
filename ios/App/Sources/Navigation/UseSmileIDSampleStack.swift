import SwiftUI

/// One tab's stack. `NavigationView` plus an `isActive` chain, the idiom the iOS 15 floor allows.
struct UseSmileIDSampleStack<Bar: View>: View {
  let tab: UseSmileIDSampleTab
  /// Inset inside the host: applied outside it, the hosted scroll view never takes the inset. Root
  /// level only, deliberately — a push covers the bar, so a pushed screen has nothing to inset for.
  @ViewBuilder let bar: () -> Bar

  var body: some View {
    NavigationView {
      UseSmileIDSampleStackLevel(tab: tab, depth: 0, route: tab.route)
        // Only the content carries the tab's identity, so switching rebuilds the screen but not
        // the host or the bar — the bar is the control that handled the tap.
        .id(tab)
        .safeAreaInset(edge: .bottom) { bar() }
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
      // Lands the level below once this one has finished arriving; see the router.
      .background(
        UseSmileIDSampleTransitionEnd { router.levelDidAppear(tab, depth: depth) }
          .frame(width: 0, height: 0)
      )
      .background(
        NavigationLink(isActive: router.isActive(tab, depth: depth)) {
          // Erased: a view whose body contains itself has no inferable body type.
          if let next = router.route(tab, depth: depth) {
            AnyView(UseSmileIDSampleStackLevel(tab: tab, depth: depth + 1, route: next))
              // Its own identity per route, so a link that swaps this level re-appears it.
              .id(next)
          }
        } label: {
          EmptyView()
        }
        .hidden()
      )
  }
}
