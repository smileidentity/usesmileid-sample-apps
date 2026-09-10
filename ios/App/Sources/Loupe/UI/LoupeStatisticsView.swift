import SwiftUI

/// What the recorded traffic adds up to.
struct LoupeStatisticsView: View {
  let statistics: LoupeStatistics

  var body: some View {
    List {
      Section("Requests") {
        LoupeDetailRow(name: "Total", value: String(statistics.total))
        LoupeDetailRow(name: "Successful", value: String(statistics.successes))
        LoupeDetailRow(name: "Failed", value: String(statistics.failures))
      }
      Section("Sizes") {
        LoupeDetailRow(name: "Request total", value: Self.bytes(statistics.requestBytes))
        LoupeDetailRow(name: "Request average", value: Self.bytes(statistics.averageRequestBytes))
        LoupeDetailRow(name: "Response total", value: Self.bytes(statistics.responseBytes))
        LoupeDetailRow(name: "Response average", value: Self.bytes(statistics.averageResponseBytes))
      }
      Section("Timing") {
        LoupeDetailRow(name: "Average", value: Self.duration(statistics.averageDuration))
        LoupeDetailRow(name: "Fastest", value: Self.duration(statistics.fastest))
        LoupeDetailRow(name: "Slowest", value: Self.duration(statistics.slowest))
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Statistics")
    .navigationBarTitleDisplayMode(.inline)
  }

  private static func bytes(_ count: Int) -> String {
    count.formatted(.byteCount(style: .file))
  }

  /// Dashed rather than zeroed when nothing was measured, so an empty run cannot read as instant.
  private static func duration(_ duration: Duration?) -> String {
    guard let duration else { return "—" }
    return duration.formatted(.units(allowed: [.seconds, .milliseconds], fractionalPart: .hide))
  }
}
