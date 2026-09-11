import Foundation

/// The broad shape of a body, which decides how the viewer renders it.
enum LoupeBodyKind: String, CaseIterable {
  case json = "JSON"
  case xml = "XML"
  case html = "HTML"
  case image = "Image"
  case other = "Other"

  /// Reads the kind from a `Content-Type`, honouring the `+json` and `+xml` structured suffixes.
  init(contentType: String) {
    let type = contentType.components(separatedBy: ";")[0]
      .trimmingCharacters(in: .whitespaces)
      .lowercased()
    if type == "application/json" || type.hasSuffix("+json") {
      self = .json
    } else if type == "application/xml" || type == "text/xml" || type.hasSuffix("+xml") {
      self = .xml
    } else if type == "text/html" {
      self = .html
    } else if type.hasPrefix("image/") {
      self = .image
    } else {
      self = .other
    }
  }
}

/// One request and whatever came back, captured whole when the exchange completes.
struct LoupeRecord: Identifiable, Equatable, Hashable {
  let id: UUID
  let method: String
  let url: URL?
  let requestDate: Date
  let requestHeaders: [String: String]
  let requestBody: Data?
  /// True when the body was a stream, which is deliberately never read.
  let isRequestBodyStreamed: Bool
  let responseDate: Date?
  let statusCode: Int?
  let responseHeaders: [String: String]
  let responseBody: Data?
  let bodyKind: LoupeBodyKind
  /// The failure the loading system reported, rendered here because `Error` is not `Sendable`.
  let errorDescription: String?

  init(
    id: UUID = UUID(),
    method: String,
    url: URL?,
    requestDate: Date,
    requestHeaders: [String: String],
    requestBody: Data?,
    isRequestBodyStreamed: Bool = false,
    responseDate: Date? = nil,
    statusCode: Int? = nil,
    responseHeaders: [String: String] = [:],
    responseBody: Data? = nil,
    bodyKind: LoupeBodyKind = .other,
    errorDescription: String? = nil
  ) {
    self.id = id
    self.method = method
    self.url = url
    self.requestDate = requestDate
    self.requestHeaders = requestHeaders
    self.requestBody = requestBody
    self.isRequestBodyStreamed = isRequestBodyStreamed
    self.responseDate = responseDate
    self.statusCode = statusCode
    self.responseHeaders = responseHeaders
    self.responseBody = responseBody
    self.bodyKind = bodyKind
    self.errorDescription = errorDescription
  }

  /// How long the exchange took, or nil while it is still open.
  var duration: Duration? {
    responseDate.map { .seconds($0.timeIntervalSince(requestDate)) }
  }

  /// True while the request is still out, which is the only way a hung call is visible at all.
  var isInFlight: Bool {
    responseDate == nil && errorDescription == nil
  }

  /// True when the exchange finished in a way the caller has to deal with.
  var isFailure: Bool {
    if errorDescription != nil {
      return true
    }
    guard let statusCode else {
      return false
    }
    return !(200..<300).contains(statusCode)
  }

  /// The path with its query, which is what identifies a call in a list of them.
  var path: String {
    guard let url else { return "" }
    let path = url.path().isEmpty ? "/" : url.path()
    guard let query = url.query() else { return path }
    return "\(path)?\(query)"
  }

  var host: String {
    url?.host() ?? ""
  }

  /// The request as a `curl` command, POSIX-quoted so a value containing a quote still runs.
  var curl: String {
    guard let url else { return "" }
    var parts = ["curl -X \(method) \(Self.shellQuoted(url.absoluteString))"]
    for key in requestHeaders.keys.sorted() {
      parts.append("-H \(Self.shellQuoted("\(key): \(requestHeaders[key] ?? "")"))")
    }
    if let requestBody, let body = String(data: requestBody, encoding: .utf8), !body.isEmpty {
      parts.append("-d \(Self.shellQuoted(body))")
    }
    return parts.joined(separator: " \\\n  ")
  }

  private static func shellQuoted(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
  }

  /// A body rendered for reading: JSON re-indented, anything else its UTF-8 text.
  static func displayBody(_ data: Data?, kind: LoupeBodyKind) -> String? {
    guard let data, !data.isEmpty else { return nil }
    if kind == .json,
       let object = try? JSONSerialization.jsonObject(with: data),
       let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
       let text = String(data: pretty, encoding: .utf8) {
      return text
    }
    return String(data: data, encoding: .utf8)
  }
}
