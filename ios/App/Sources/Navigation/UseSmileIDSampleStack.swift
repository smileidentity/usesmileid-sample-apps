import SwiftUI

/// One tab's stack. On the SDK's iOS 15 floor a stack is a `NavigationView` plus a chain of
/// `isActive` links — the pre-`NavigationStack` idiom, which still supports an arbitrary depth and
/// a fully programmatic path, so deep links and restoration behave as they would on 16.
struct UseSmileIDSampleStack: View {
  let tab: UseSmileIDSampleTab

  var body: some View {
    NavigationView {
      UseSmileIDSampleStackLevel(tab: tab, depth: 0, route: tab.route)
    }
    .navigationViewStyle(.stack)
  }
}

/// Renders the route at this level and hosts the link to the one below it.
private struct UseSmileIDSampleStackLevel: View {
  let tab: UseSmileIDSampleTab
  let depth: Int
  let route: Route
  @EnvironmentObject private var router: UseSmileIDSampleRouter

  var body: some View {
    UseSmileIDSampleDestination(route: route)
      .background(
        NavigationLink(isActive: router.isActive(tab, depth: depth)) {
          // Erased once: a view whose body contains itself has no inferable body type.
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
