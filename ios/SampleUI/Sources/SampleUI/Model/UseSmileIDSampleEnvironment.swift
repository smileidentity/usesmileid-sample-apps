import Foundation

/// Sandbox or production; there is no third case, and the SDK's own URL constants resolve to the same two hosts.
public enum UseSmileIDSampleEnvironment: String, CaseIterable, Sendable {
  case sandbox
  case production

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .sandbox: "Sandbox"
    case .production: "Production"
    }
  }

  public var host: String {
    switch self {
    case .sandbox: "testapi.smileidentity.com"
    case .production: "api.smileidentity.com"
    }
  }

  /// Trailing slash, which is the form the SDK's own constants take.
  public var baseUrl: String {
    "https://\(host)/"
  }

  /// A token's `api_url` onto an environment. On the parsed host, never the whole string: a real
  /// claim carries a `/v3` path and no trailing slash, so a string compare misses, and misses silently.
  public static func of(apiUrl: String?) -> UseSmileIDSampleEnvironment? {
    guard let host = apiUrlHost(apiUrl) else { return nil }
    return allCases.first { $0.host == host }
  }

  /// The host an `api_url` names, so a rejection can say which one it saw. Nil when the value carries none.
  public static func apiUrlHost(_ apiUrl: String?) -> String? {
    guard let trimmed = apiUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
      return nil
    }
    return URLComponents(string: trimmed)?.host?.lowercased()
  }
}
