import SampleUI
import SwiftUI

/// Who draws each part of the Settings DEBUG section below Scenarios.
enum UseSmileIDSampleDebugRowGroup: CaseIterable {
  /// The extension's leading rows, such as a device identity.
  case extensionLeading
  /// The shell's own rows: Network logs.
  case shell
  /// The extension's other rows, such as Show diagnostics.
  case `extension`
}

/// The DEBUG section's rows below Scenarios, in the order a source build's rows rely on.
struct UseSmileIDSampleDebugRows: View {
  let `extension`: (any UseSmileIDSampleShellExtending.Type)?

  var body: some View {
    ForEach(UseSmileIDSampleDebugRowGroup.allCases, id: \.self) { group in
      switch group {
      case .extensionLeading:
        `extension`?.leadingDebugRows() ?? AnyView(EmptyView())
      case .shell:
        UseSmileIDSampleNetworkLogsRow()
      case .extension:
        `extension`?.debugRows() ?? AnyView(EmptyView())
      }
    }
  }
}

/// Opens Loupe, the debug build's network log; a release build records nothing, so it draws nothing.
struct UseSmileIDSampleNetworkLogsRow: View {
  var body: some View {
    #if DEBUG
      UseSmileIDSampleSettingRow(
        title: "Network logs",
        supportingText: "The last 500 requests",
        onTap: { Loupe.shared.isPresented = true },
        trailing: { UseSmileIDSampleSettingRowChevron() }
      )
    #else
      EmptyView()
    #endif
  }
}
