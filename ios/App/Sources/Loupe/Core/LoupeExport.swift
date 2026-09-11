import Foundation

/// Renders records as the plain text a bug report wants pasted into it.
enum LoupeExport {
  /// One exchange: the curl that reproduces it, then what came back.
  static func text(for record: LoupeRecord) -> String {
    var lines = [record.curl, ""]
    if let statusCode = record.statusCode {
      lines.append("Status: \(statusCode)")
    }
    if let errorDescription = record.errorDescription {
      lines.append("Error: \(errorDescription)")
    }
    if !record.responseHeaders.isEmpty {
      lines.append("")
      lines.append("Response headers:")
      lines.append(contentsOf: record.responseHeaders.keys.sorted().map {
        "  \($0): \(record.responseHeaders[$0] ?? "")"
      })
    }
    if let body = LoupeRecord.displayBody(record.responseBody, kind: record.bodyKind) {
      lines.append("")
      lines.append("Response body:")
      lines.append(body)
    }
    return lines.joined(separator: "\n")
  }

  /// The whole session, oldest first, so the transcript reads in the order it happened.
  static func text(for records: [LoupeRecord]) -> String {
    records
      .reversed()
      .map(text(for:))
      .joined(separator: "\n\n" + String(repeating: "─", count: 40) + "\n\n")
  }
}
