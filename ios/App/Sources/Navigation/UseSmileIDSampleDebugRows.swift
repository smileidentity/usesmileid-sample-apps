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
  /// Opens the extension's debug sheet by id.
  var openSheet: (String) -> Void = { _ in }

  var body: some View {
    ForEach(UseSmileIDSampleDebugRowGroup.allCases, id: \.self) { group in
      switch group {
      case .extensionLeading:
        `extension`?.leadingDebugRows() ?? AnyView(EmptyView())
      case .shell:
        UseSmileIDSampleNetworkLogsRow()
      case .extension:
        `extension`?.debugRows(openSheet: openSheet) ?? AnyView(EmptyView())
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
        leading: { UseSmileIDSampleNetworkLogsIcon() },
        trailing: { UseSmileIDSampleSettingRowChevron() }
      )
    #else
      EmptyView()
    #endif
  }
}

/// The Network logs row's glyph, tinted as Settings tints every row's.
private struct UseSmileIDSampleNetworkLogsIcon: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    UseSmileIDSampleIcon(SmileIcons.receiptLong, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
  }
}

/// A sheet the extension draws for one of its DEBUG rows; a release build, or one with no extension, closes it at once.
struct UseSmileIDSampleDebugSheet: View {
  let sheetId: String
  let `extension`: (any UseSmileIDSampleShellExtending.Type)?
  let onDismiss: () -> Void

  var body: some View {
    if let `extension`, useSmileIDSampleDebugSheetOpens(debugBuild: useSmileIDSampleIsDebugBuild, hasExtension: true) {
      `extension`.debugSheet(sheetId, onDismiss: onDismiss)
    } else {
      Color.clear.onAppear(perform: onDismiss)
    }
  }
}

/// Whether a debug sheet opens: only a debug build with an extension has one to draw.
func useSmileIDSampleDebugSheetOpens(debugBuild: Bool, hasExtension: Bool) -> Bool {
  debugBuild && hasExtension
}

/// Whether this binary is a debug build.
let useSmileIDSampleIsDebugBuild: Bool = {
  #if DEBUG
    true
  #else
    false
  #endif
}()
