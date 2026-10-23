import SampleUI
import SwiftUI

/// The DEBUG section's rows below Scenarios: an identity the extension leads with, then the shell's network log, then
/// the extension's other rows.
struct UseSmileIDSampleDebugRows: View {
  let `extension`: (any UseSmileIDSampleShellExtending.Type)?
  let host: UseSmileIDSampleShellHost

  var body: some View {
    `extension`?.leadingDebugRows(host: host) ?? AnyView(EmptyView())
    UseSmileIDSampleNetworkLogsRow()
    `extension`?.debugRows(host: host) ?? AnyView(EmptyView())
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
