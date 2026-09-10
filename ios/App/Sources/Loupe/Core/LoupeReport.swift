import Foundation

/// The one-paste bug report: what the device is, what the window covered, then the traffic.
///
/// Borrowed from DebugOverlay-Android, whose report bundles diagnostics with the log so a repro
/// arrives as one artefact rather than a screenshot and a promise.
enum LoupeReport {
  static func text(records: [LoupeRecord], since: Date) -> String {
    let statistics = LoupeStatistics(records: records)
    var lines = ["# Network report", ""]
    lines.append(contentsOf: [
      "App: \(value(for: "CFBundleName")) \(version)",
      "Bundle: \(Bundle.main.bundleIdentifier ?? "—")",
      "System: \(ProcessInfo.processInfo.operatingSystemVersionString)",
      "Window opened: \(since.formatted(date: .abbreviated, time: .standard))",
      "Reported: \(Date().formatted(date: .abbreviated, time: .standard))",
      "",
      "Requests: \(statistics.total) — \(statistics.successes) ok, \(statistics.failures) failed"
    ])
    if let average = statistics.averageDuration {
      lines.append("Timing: \(format(average)) average, \(format(statistics.slowest)) slowest")
    }
    lines.append("")
    lines.append(String(repeating: "=", count: 40))
    lines.append("")
    lines.append(LoupeExport.text(for: records))
    return lines.joined(separator: "\n")
  }

  private static func format(_ duration: Duration?) -> String {
    guard let duration else {
      return "—"
    }
    return duration.formatted(.units(allowed: [.seconds, .milliseconds], fractionalPart: .hide))
  }

  private static var version: String {
    "\(value(for: "CFBundleShortVersionString")) (\(value(for: "CFBundleVersion")))"
  }

  private static func value(for key: String) -> String {
    Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "—"
  }
}
