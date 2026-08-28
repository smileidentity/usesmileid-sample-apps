import Foundation
import SwiftUI

/// The typed path router. Each tab keeps its own stack (R7), the selected tab and every stack are
/// `Codable` so restoration is a decode, and a sheet is held here as a request rather than pushed.
///
/// `ObservableObject` rather than `@Observable`: this library's floor is the SDK's, iOS 15.
@MainActor
final class UseSmileIDSampleRouter: ObservableObject {
  @Published var selectedTab: UseSmileIDSampleTab = .products
  @Published var paths: [UseSmileIDSampleTab: [Route]] = [:]

  /// The sheet the owning screen is showing. One at a time, because two cannot be presented at once.
  @Published var sheet: Sheet?

  /// Whether a link or a restore has already decided where the app opens. On a cold start the two
  /// race, and whichever the system delivers first must win — a later restore would discard the link.
  private(set) var hasOpened = false

  func path(_ tab: UseSmileIDSampleTab) -> [Route] {
    paths[tab] ?? []
  }

  func push(_ route: Route) {
    paths[route.tab, default: []].append(route)
    selectedTab = route.tab
  }

  /// Assigns the whole path at once, so a detail link restores its parent stack in one write.
  /// A tab's own route is the stack's root rather than an entry on it, so it clears the stack.
  func open(_ route: Route) {
    hasOpened = true
    paths[route.tab] = route == route.tab.route ? [] : route.parents + [route]
    selectedTab = route.tab
  }

  func openTabRoot(_ tab: UseSmileIDSampleTab) {
    paths[tab] = []
    selectedTab = tab
  }

  /// True while the stack is deeper than `depth`; setting it false pops back to exactly that depth.
  func isActive(_ tab: UseSmileIDSampleTab, depth: Int) -> Binding<Bool> {
    Binding(
      get: { [weak self] in (self?.path(tab).count ?? 0) > depth },
      set: { [weak self] active in
        guard let self, !active else { return }
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

/// What `@SceneStorage` persists: the selected tab and every stack, as one decodable value.
struct UseSmileIDSampleNavigationState: Codable {
  var selectedTab: UseSmileIDSampleTab
  var paths: [UseSmileIDSampleTab: [Route]]
}

extension UseSmileIDSampleRouter {
  var restorationState: UseSmileIDSampleNavigationState {
    UseSmileIDSampleNavigationState(selectedTab: selectedTab, paths: paths)
  }

  /// A decode that cannot throw its way into a blank window: unreadable state restores the default.
  /// Skipped once a link has opened something, because on a cold start the link may arrive first.
  func restore(from encoded: String) {
    guard !hasOpened else { return }
    hasOpened = true
    guard let data = encoded.data(using: .utf8),
          let state = try? JSONDecoder().decode(UseSmileIDSampleNavigationState.self, from: data)
    else { return }
    selectedTab = state.selectedTab
    paths = state.paths
  }

  func encodedState() -> String {
    guard let data = try? JSONEncoder().encode(restorationState) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }
}
