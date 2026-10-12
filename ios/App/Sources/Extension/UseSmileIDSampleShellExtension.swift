import SampleUI
import SwiftUI
import UseSmileID

/// Developer tooling an SDK repo's source build adds to this app; a registry build has none.
@MainActor
protocol UseSmileIDSampleShellExtending {
  /// Extra rows for the Settings DEBUG section, which debug builds show.
  static func debugRows(host: UseSmileIDSampleShellHost) -> AnyView
  /// Runs after the shell has configured a flow, so it may replace any of that configuration.
  static func customiseFlow(_ builder: UseSmileIDFlowBuilder, product: UseSmileIDSampleProduct)
  /// Runs once at launch.
  static func onLaunch()
}

extension UseSmileIDSampleShellExtending {
  static func debugRows(host _: UseSmileIDSampleShellHost) -> AnyView {
    AnyView(EmptyView())
  }

  static func customiseFlow(_: UseSmileIDFlowBuilder, product _: UseSmileIDSampleProduct) {}
  static func onLaunch() {}
}

/// What the shell lets an extension do.
@MainActor
struct UseSmileIDSampleShellHost {
  let linkTokenSession: (UseSmileIDSampleTokenSession) -> Void
  let openScenarioDrawer: () -> Void
}

/// The type an SDK repo's add-on extends to conform to `UseSmileIDSampleShellExtending`.
enum UseSmileIDSampleShellExtensionPoint {}

/// The extension compiled into this build, if any.
@MainActor
var useSmileIDSampleShellExtension: (any UseSmileIDSampleShellExtending.Type)? {
  (UseSmileIDSampleShellExtensionPoint.self as Any) as? any UseSmileIDSampleShellExtending.Type
}
