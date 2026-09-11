import Foundation

/// Masks the credentials a recorded exchange would otherwise carry in clear.
///
/// Applied where the record is built, not where it is shown: a value the store never holds cannot
/// leak through an export, a share sheet, or a screenshot of the detail screen.
enum LoupeRedaction {
  /// Headers whose value is a credential rather than a fact about the request.
  ///
  /// `smileid-partner-id` and the `smileid-source-sdk*` headers are deliberately absent — they
  /// identify the caller without authenticating it, and masking them would cost the debugging they
  /// exist for.
  static let secretHeaders: Set<String> = [
    "authorization",
    "cookie",
    "proxy-authorization",
    "set-cookie",
    "smileid-api-key",
    "smileid-request-mac",
    "smileid-token",
    "x-api-key"
  ]

  /// JSON keys whose value is a credential. The auth response carries the token in its body, so
  /// masking only headers would leave it in clear on the one call that mints it.
  static let secretBodyKeys: Set<String> = [
    "api_key",
    "apikey",
    "password",
    "secret",
    "signature",
    "token"
  ]

  /// The first five characters and five asterisks, so a value stays recognisable without being
  /// usable. Anything five characters or shorter is masked whole rather than revealed entire.
  static func mask(_ value: String) -> String {
    guard value.count > 5 else {
      return "*****"
    }
    return value.prefix(5) + "*****"
  }

  /// Masks every credential header, matching the name case-insensitively because HTTP does.
  static func headers(_ headers: [String: String]) -> [String: String] {
    headers.reduce(into: [:]) { result, entry in
      result[entry.key] = secretHeaders.contains(entry.key.lowercased())
        ? mask(entry.value)
        : entry.value
    }
  }

  /// Masks credential values in a JSON body, at any depth, leaving everything else untouched.
  ///
  /// A body that is not JSON is returned as it came: guessing at credentials in an arbitrary
  /// payload would mangle the thing being debugged more often than it would protect anything.
  static func body(_ data: Data?) -> Data? {
    guard let data,
          let parsed = try? JSONSerialization.jsonObject(with: data),
          let masked = try? JSONSerialization.data(withJSONObject: redact(parsed)) else {
      return data
    }
    return masked
  }

  private static func redact(_ value: Any) -> Any {
    if let object = value as? [String: Any] {
      return object.reduce(into: [String: Any]()) { result, entry in
        if secretBodyKeys.contains(entry.key.lowercased()), let text = entry.value as? String {
          result[entry.key] = mask(text)
        } else {
          result[entry.key] = redact(entry.value)
        }
      }
    }
    if let array = value as? [Any] {
      return array.map(redact)
    }
    return value
  }
}
