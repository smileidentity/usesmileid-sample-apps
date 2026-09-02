import Foundation
import SwiftUI

/// The typed path router: a `Codable` stack per tab, so restoration is a decode.
/// `ObservableObject` rather than `@Observable` because the floor is the SDK's, iOS 15.
@MainActor
final class UseSmileIDSampleRouter: ObservableObject {
  @Published var selectedTab: UseSmileIDSampleTab = .products
  @Published var paths: [UseSmileIDSampleTab: [Route]] = [:]

  /// One at a time, because two sheets cannot be presented at once.
  @Published var sheet: Sheet?

  /// On a cold start a link and a restore race; whichever lands first wins.
  private(set) var hasOpened = false

  func path(_ tab: UseSmileIDSampleTab) -> [Route] {
    paths[tab] ?? []
  }

  func push(_ route: Route) {
    paths[route.tab, default: []].append(route)
    selectedTab = route.tab
  }

  /// Assigns the whole path at once; a tab's own route is the root, so it clears the stack.
  func open(_ route: Route) {
    hasOpened = true
    paths[route.tab] = route == route.tab.route ? [] : route.parents + [route]
    selectedTab = route.tab
  }

  /// Drops the deepest route on the showing tab: what a pushed screen's own back control calls.
  func pop() {
    guard var next = paths[selectedTab], !next.isEmpty else { return }
    next.removeLast()
    paths[selectedTab] = next
  }

  func openTabRoot(_ tab: UseSmileIDSampleTab) {
    paths[tab] = []
    selectedTab = tab
  }

  /// Setting it false pops back to exactly `depth`.
  func isActive(_ tab: UseSmileIDSampleTab, depth: Int) -> Binding<Bool> {
    Binding(
      get: { [weak self] in (self?.path(tab).count ?? 0) > depth },
      set: { [weak self] active in
        guard let self, !active else { return }
        // Only the showing tab pops. Tearing down the outgoing tab's stack fires this setter too,
        // and acting on it would drop the path the user is navigating away from.
        guard self.selectedTab == tab else { return }
        var next = self.path(tab)
        guard next.count > depth else { return }
        next.removeSubrange(depth...)
        self.paths[tab] = next
      }
    )
  }

  func route(_ tab: UseSmileIDSampleTab, depth: Int) -> Route? {
    let stack = path(tab)
    return depth < stack.count ? stack[depth] : nil
  }
}

/// What `@SceneStorage` persists, as one decodable value.
struct UseSmileIDSampleNavigationState: Codable {
  var selectedTab: UseSmileIDSampleTab
  var paths: [UseSmileIDSampleTab: [Route]]
}

extension UseSmileIDSampleRouter {
  var restorationState: UseSmileIDSampleNavigationState {
    UseSmileIDSampleNavigationState(selectedTab: selectedTab, paths: paths)
  }

  /// Unreadable state restores the default rather than throwing into a blank window.
  func restore(from encoded: String) {
    guard !hasOpened else { return }
    hasOpened = true
    guard let data = encoded.data(using: .utf8),
          let state = try? JSONDecoder().decode(UseSmileIDSampleNavigationState.self, from: data)
    else { return }
    selectedTab = state.selectedTab
    // Decodable is not current: an older route table could seat a route under the wrong tab.
    paths = state.paths.filter { tab, routes in routes.allSatisfy { $0.tab == tab } }
  }

  func encodedState() -> String {
    guard let data = try? JSONEncoder().encode(restorationState) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }
}
