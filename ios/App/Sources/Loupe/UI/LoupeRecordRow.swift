import SwiftUI

/// One exchange in the list: what it was, how it went, and how long it took.
struct LoupeRecordRow: View {
  let record: LoupeRecord

  var body: some View {
    HStack(spacing: 10) {
      Text(statusText)
        .font(.caption.monospacedDigit().bold())
        .foregroundStyle(.white)
        .frame(width: 44, height: 24)
        .background(statusColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))

      VStack(alignment: .leading, spacing: 2) {
        Text("\(record.method) \(record.path)")
          .font(.footnote.weight(.semibold))
          .lineLimit(1)
          .truncationMode(.middle)
        HStack(spacing: 6) {
          Text(record.host)
            .lineLimit(1)
            .truncationMode(.head)
          if let duration = record.duration {
            Text(duration.formatted(.units(allowed: [.seconds, .milliseconds], fractionalPart: .hide)))
          }
          Text(record.bodyKind.rawValue)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 2)
  }

  /// A transport failure has no status code, so the badge says so rather than reading as pending.
  private var statusText: String {
    if record.errorDescription != nil { return "ERR" }
    guard let statusCode = record.statusCode else { return "…" }
    return String(statusCode)
  }

  private var statusColor: Color {
    if record.errorDescription != nil { return .red }
    guard let statusCode = record.statusCode else { return .gray }
    switch statusCode {
    case 200..<300: return .green
    case 300..<400: return .blue
    case 400..<500: return .orange
    default: return .red
    }
  }
}
