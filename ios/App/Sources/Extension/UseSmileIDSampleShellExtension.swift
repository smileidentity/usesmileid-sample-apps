import SampleUI
import SwiftUI
import UseSmileID

/// Developer tooling an SDK repo's source build adds to this app; a registry build has none.
@MainActor
protocol UseSmileIDSampleShellExtending {
  /// Extra rows for the Settings DEBUG section, which debug builds show.
  static func debugRows() -> AnyView
  /// Runs after the shell has configured a flow, so it may replace any of that configuration.
  static func customiseFlow(_ builder: UseSmileIDFlowBuilder, product: UseSmileIDSampleProduct)
  /// Runs last inside the shell's network block, so it may add to that configuration without replacing it.
  static func customiseNetwork(_ network: UseSmileIDNetworkBuilder, product: UseSmileIDSampleProduct)
  /// Runs once at launch, in `App.init`, before any other member.
  static func onLaunch()
  /// A session the shell links once, after `onLaunch` and before autostart, as if its token had been scanned.
  static func launchSession() -> UseSmileIDSampleTokenSession?
}

extension UseSmileIDSampleShellExtending {
  static func debugRows() -> AnyView {
    AnyView(EmptyView())
  }

  static func customiseFlow(_: UseSmileIDFlowBuilder, product _: UseSmileIDSampleProduct) {}
  static func customiseNetwork(_: UseSmileIDNetworkBuilder, product _: UseSmileIDSampleProduct) {}
  static func onLaunch() {}
  static func launchSession() -> UseSmileIDSampleTokenSession? {
    nil
  }
}

/// Links the extension's launch session, if it offers one.
@MainActor
func linkLaunchSession(
  _ extension: (any UseSmileIDSampleShellExtending.Type)?,
  link: (UseSmileIDSampleTokenSession) -> Void
) {
  if let session = `extension`?.launchSession() {
    link(session)
  }
}

/// The type an SDK repo's add-on extends to conform to `UseSmileIDSampleShellExtending`.
enum UseSmileIDSampleShellExtensionPoint {}

/// The extension compiled into this build, if any.
@MainActor
var useSmileIDSampleShellExtension: (any UseSmileIDSampleShellExtending.Type)? {
  (UseSmileIDSampleShellExtensionPoint.self as Any) as? any UseSmileIDSampleShellExtending.Type
}
