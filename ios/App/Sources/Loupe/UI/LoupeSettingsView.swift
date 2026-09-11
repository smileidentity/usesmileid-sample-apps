import SwiftUI

/// Recording state, what is being skipped, the host this build is running as, and what the
/// loupe was offered — three counters that localise a call that went unrecorded.
struct LoupeSettingsView: View {
  let loupe: Loupe
  let recordCount: Int
  let onClear: () -> Void

  var body: some View {
    List {
      Section("Recording") {
        Toggle("Record traffic", isOn: Binding(
          get: { loupe.isRecording },
          set: { $0 ? loupe.start() : loupe.stop() }
        ))
        LoupeDetailRow(name: "Recorded this launch", value: String(recordCount))
      }

      if !loupe.ignoredURLPrefixes.isEmpty {
        Section("Skipped") {
          ForEach(loupe.ignoredURLPrefixes, id: \.self) { prefix in
            Text(prefix).font(.caption.monospaced())
          }
        }
      }

      Section("Host") {
        LoupeDetailRow(name: "App", value: Self.value(for: "CFBundleName"))
        LoupeDetailRow(name: "Version", value: Self.version)
        LoupeDetailRow(name: "Bundle id", value: Bundle.main.bundleIdentifier ?? "—")
        LoupeDetailRow(name: "System", value: "\(Self.systemName) \(Self.systemVersion)")
      }

      Section("Diagnostics") {
        let diagnostics = LoupeDiagnostics.shared.current
        LoupeDetailRow(name: "Sessions instrumented", value: String(diagnostics.instrumentedSessions))
        LoupeDetailRow(name: "Requests offered", value: String(diagnostics.offered))
        LoupeDetailRow(name: "Requests declined", value: String(diagnostics.declined))
        ForEach(diagnostics.reasons, id: \.self) { reason in
          Text(reason)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
        }
      }

      Section {
        Button("Clear recorded traffic", role: .destructive, action: onClear)
          .disabled(recordCount == 0)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }

  private static var version: String {
    let short = value(for: "CFBundleShortVersionString")
    let build = value(for: "CFBundleVersion")
    return "\(short) (\(build))"
  }

  private static func value(for key: String) -> String {
    Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "—"
  }

  private static var systemName: String {
    ProcessInfo.processInfo.isiOSAppOnMac ? "iOS on Mac" : "iOS"
  }

  private static var systemVersion: String {
    ProcessInfo.processInfo.operatingSystemVersionString
  }
}
