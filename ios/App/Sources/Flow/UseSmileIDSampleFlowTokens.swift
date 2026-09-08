import Foundation
import SampleUI

/// Structurally valid unsigned JWTs — fixtures a simulated scan links, never credentials.
enum UseSmileIDSampleFlowTokens {
  /// What a run with no scanned session submits under. Structurally valid: the scenarios demand a
  /// well-formed JWT whose `exp` is in the past, not a garbage string.
  static func token(expired: Bool, now: Date) -> String {
    let seconds = Int64(now.timeIntervalSince1970)
    let exp = seconds + (expired ? -validitySeconds : validitySeconds)
    return [header, "{\"exp\":\(exp)}", signature].map(base64Url).joined(separator: ".")
  }

  /// What `badRefresh` refreshes to.
  static func malformed() -> String {
    "sample-not-a-jwt"
  }

  /// What a simulated scan links. The same unsigned shape a real token has, over the chosen span
  /// and carrying the chosen bindings — enough to exercise every client-side rule, because the SDK
  /// decodes a token but never verifies one. What it cannot exercise is a server accepting it.
  ///
  /// The PII values are deliberate nonsense: a real token carries an opaque vault reference in their
  /// place, so no plausible-looking name or number belongs in a fixture.
  static func session(
    span: UseSmileIDSampleSimulatedSpan,
    bindings: UseSmileIDSampleSimulatedBindings,
    environment: UseSmileIDSampleEnvironment,
    now: Date
  ) -> String {
    let nowSeconds = Int64(now.timeIntervalSince1970)
    let spanSeconds = Int64(span.span)
    // An ended span is minted wholly in the past, which is the only way to reach the expiry gate.
    let issuedAt = span.isEnded ? nowSeconds - spanSeconds - endedLagSeconds : nowSeconds
    var claims = [
      "\"iat\":\(issuedAt)",
      "\"exp\":\(issuedAt + spanSeconds)",
      // With the path a real claim carries, so the fixture exercises the host match.
      "\"api_url\":\"\(environment.baseUrl)\(apiPath)\""
    ]
    if bindings.binds {
      claims.append(payloadClaim(bindings, issuedAt: issuedAt))
    }
    return [header, "{" + claims.joined(separator: ",") + "}", signature].map(base64Url).joined(separator: ".")
  }

  private static func payloadClaim(_ bindings: UseSmileIDSampleSimulatedBindings, issuedAt: Int64) -> String {
    var fields: [String] = []
    if bindings.userDetails {
      fields += vaultedFields.map { "\"\($0)\":\"vault_\($0)\"" }
      // The two the Portal leaves in plaintext, so a decode can read them back.
      fields.append("\"country\":\"\(UseSmileIDSampleCountry.kenya.code)\"")
      fields.append("\"id_type\":\"\(UseSmileIDSampleIdType.nationalId.id)\"")
    }
    if bindings.consent {
      fields.append(consentClaim(issuedAt: issuedAt))
    }
    return "\"payload\":{" + fields.joined(separator: ",") + "}"
  }

  /// All four subfields: the SDK treats a partial binding as a build error, not a partial relaxation.
  private static func consentClaim(issuedAt: Int64) -> String {
    let grantedAt = grantedAtFormat.string(from: Date(timeIntervalSince1970: TimeInterval(issuedAt)))
    return "\"consent\":{\"granted\":true,\"granted_at\":\"\(grantedAt)\","
      + "\"notice_language\":\"en\",\"notice_privacy_policy_url\":\"\(privacyPolicyUrl)\"}"
  }

  private static func base64Url(_ value: String) -> String {
    Data(value.utf8).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private static let grantedAtFormat: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return formatter
  }()

  private static let header = #"{"alg":"none","typ":"JWT"}"#
  private static let signature = "sample-signature"
  private static let endedLagSeconds: Int64 = 60
  private static let validitySeconds: Int64 = 3600
  private static let apiPath = "v3"
  private static let privacyPolicyUrl = "https://smile.id/privacy-policy"
  private static let vaultedFields = ["given_names", "last_name", "email", "phone_number", "id_number"]
}
