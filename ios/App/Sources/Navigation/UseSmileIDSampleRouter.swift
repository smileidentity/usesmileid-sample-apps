import Foundation
import SwiftUI

/// The typed path router: a `Codable` stack per tab, so restoration is a decode.
/// `ObservableObject` rather than `@Observable` because the floor is the SDK's, iOS 15.
@MainActor
final class UseSmileIDSampleRouter: ObservableObject {
  /// One tab is mounted at a time, so the tab coming on screen lands its stack from the root again.
  @Published var selectedTab: UseSmileIDSampleTab = .products {
    didSet {
      if selectedTab != oldValue {
        landed[selectedTab] = min(1, path(selectedTab).count)
      }
    }
  }

  @Published var paths: [UseSmileIDSampleTab: [Route]] = [:]

  /// How many of each tab's routes are on screen. A link or a restore lands them one per finished
  /// transition, because the iOS 15 `NavigationView` idiom drops a push made while another is in flight.
  @Published private(set) var landed: [UseSmileIDSampleTab: Int] = [:]

  /// One at a time, because two sheets cannot be presented at once.
  @Published var sheet: Sheet?

  /// On a cold start a link and a restore race; whichever lands first wins.
  private(set) var hasOpened = false

  func path(_ tab: UseSmileIDSampleTab) -> [Route] {
    paths[tab] ?? []
  }

  /// A tap pushes one level, so it lands at once and animates as the platform does. Bounded to one
  /// step: landing more while a linked path is still arriving is the drop this router exists to avoid.
  func push(_ route: Route) {
    paths[route.tab, default: []].append(route)
    landed[route.tab] = min(landedCount(route.tab) + 1, path(route.tab).count)
    selectedTab = route.tab
  }

  /// A push that stays single: two quick taps on the token affordance must not stack two scanners.
  func pushOnce(_ route: Route) {
    guard path(route.tab).last != route else { return }
    push(route)
  }

  /// Assigns the whole path at once; a tab's own route is the root, so it clears the stack. A sheet
  /// goes with what it was layered over, as the Compose owner disposes its sheet on navigation.
  func open(_ route: Route) {
    hasOpened = true
    sheet = nil
    let full = route == route.tab.route ? [] : route.parents + [route]
    // The levels already showing stay landed, so a link lands from the deepest of them, not the root.
    let showing = zip(path(route.tab).prefix(landedCount(route.tab)), full).prefix { $0 == $1 }.count
    // Unanimated past one level, so the first push is over before the level after it lands.
    withoutAnimation(full.count > 1) {
      paths[route.tab] = full
      landed[route.tab] = min(showing + 1, full.count)
    }
    selectedTab = route.tab
  }

  /// Called as each level's transition ends: lands the next one, if the path has one.
  func levelDidAppear(_ tab: UseSmileIDSampleTab, depth: Int) {
    guard landedCount(tab) == depth, path(tab).count > depth else { return }
    withoutAnimation(true) {
      landed[tab] = depth + 1
    }
  }

  /// Drops the deepest route on the showing tab: what a pushed screen's own back control calls.
  func pop() {
    guard var next = paths[selectedTab], !next.isEmpty else { return }
    next.removeLast()
    set(next, on: selectedTab)
  }

  func openTabRoot(_ tab: UseSmileIDSampleTab) {
    set([], on: tab)
    selectedTab = tab
  }

  /// Setting it false pops back to exactly `depth`.
  func isActive(_ tab: UseSmileIDSampleTab, depth: Int) -> Binding<Bool> {
    Binding(
      get: { [weak self] in (self?.landedCount(tab) ?? 0) > depth },
      set: { [weak self] active in
        guard let self, !active else { return }
        // Only the showing tab pops. Tearing down the outgoing tab's stack fires this setter too,
        // and acting on it would drop the path the user is navigating away from.
        guard self.selectedTab == tab else { return }
        var next = self.path(tab)
        guard next.count > depth else { return }
        next.removeSubrange(depth...)
        self.set(next, on: tab)
      }
    )
  }

  func route(_ tab: UseSmileIDSampleTab, depth: Int) -> Route? {
    let stack = path(tab)
    return depth < stack.count ? stack[depth] : nil
  }

  private func landedCount(_ tab: UseSmileIDSampleTab) -> Int {
    landed[tab] ?? 0
  }

  /// A shorter path can never leave more levels landed than it has.
  private func set(_ routes: [Route], on tab: UseSmileIDSampleTab) {
    paths[tab] = routes
    landed[tab] = min(landedCount(tab), routes.count)
  }

  private func withoutAnimation(_ disabled: Bool, _ change: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = disabled
    withTransaction(transaction, change)
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
    // Decodable is not current: an older route table could seat a route under the wrong tab.
    let valid = state.paths.filter { tab, routes in routes.allSatisfy { $0.tab == tab } }
    // A restored stack lands the way a link does, and nothing about a launch should animate.
    withoutAnimation(true) {
      selectedTab = state.selectedTab
      paths = valid
      landed = valid.mapValues { min(1, $0.count) }
    }
  }

  func encodedState() -> String {
    guard let data = try? JSONEncoder().encode(restorationState) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }
}
