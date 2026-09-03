import CryptoKit
import Foundation

/// What a v3 token binds. The SDK reads the same claim and exposes presence flags only, because every
/// PII value in it is swapped for a vault token before signing — `country` and `idType` are the two
/// that arrive in plaintext.
public struct UseSmileIDSampleTokenBindings: Equatable, Sendable, CustomStringConvertible {
  public var givenNames: Bool
  public var lastName: Bool
  public var email: Bool
  public var phoneNumber: Bool
  public var consent: UseSmileIDSampleTokenConsent?
  public var country: String?
  public var idType: String?
  /// The vault reference standing in for the ID number, which is the only form a token carries it in.
  public var idNumberReference: String?

  public init(
    givenNames: Bool = false,
    lastName: Bool = false,
    email: Bool = false,
    phoneNumber: Bool = false,
    consent: UseSmileIDSampleTokenConsent? = nil,
    country: String? = nil,
    idType: String? = nil,
    idNumberReference: String? = nil
  ) {
    self.givenNames = givenNames
    self.lastName = lastName
    self.email = email
    self.phoneNumber = phoneNumber
    self.consent = consent
    self.country = country
    self.idType = idType
    self.idNumberReference = idNumberReference
  }

  /// Redacted like the session's: every one of these is a claim value, and one is a vault reference.
  public var description: String {
    "UseSmileIDSampleTokenBindings(givenNames=\(givenNames), lastName=\(lastName), email=\(email), "
      + "phoneNumber=\(phoneNumber), consent=\(consent != nil), country=\(country != nil), "
      + "idType=\(idType != nil), idNumberReference=\(idNumberReference != nil))"
  }

  /// Whether the token binds enough for the SDK to stop requiring `userDetails` — both names plus
  /// one contact field. A duplicate of the SDK's own rule, which is internal; the unit tests pin it.
  public var bindsRequiredUserDetails: Bool {
    UseSmileIDSampleUserDetailsRequirement(bindings: self).isSatisfied
  }

  /// Whether the token carries every ID parameter `product` submits. Stricter than Document
  /// Verification's validator, which accepts a nil ID type: the form is where the document type is chosen.
  public func bindsIdDetails(_ product: UseSmileIDSampleProduct) -> Bool {
    switch product {
    case .enhancedKyc, .biometricKyc:
      !country.isBlankOrNil && !idType.isBlankOrNil && !idNumberReference.isBlankOrNil
    case .documentVerification, .enhancedDocumentVerification:
      !country.isBlankOrNil && !idType.isBlankOrNil
    case .smartSelfieEnrollment, .smartSelfieAuth:
      true
    }
  }
}

/// The consent record bound into the token. `granted` is `true` or absent by construction, mirroring
/// the SDK reading `granted: false` as no binding at all.
public struct UseSmileIDSampleTokenConsent: Equatable, Sendable {
  public var granted: Bool?
  public var grantedAt: String?
  public var noticeLanguage: String?
  public var noticePrivacyPolicyUrl: String?

  public init(
    granted: Bool? = nil,
    grantedAt: String? = nil,
    noticeLanguage: String? = nil,
    noticePrivacyPolicyUrl: String? = nil
  ) {
    self.granted = granted
    self.grantedAt = grantedAt
    self.noticeLanguage = noticeLanguage
    self.noticePrivacyPolicyUrl = noticePrivacyPolicyUrl
  }

  /// True when the token alone satisfies consent — which is when the SDK drops its consent screen.
  public var isComplete: Bool {
    granted == true && !grantedAt.isBlankOrNil && !noticeLanguage.isBlankOrNil && !noticePrivacyPolicyUrl.isBlankOrNil
  }
}

/// Either the session a token describes, or why it is not one.
public enum UseSmileIDSampleTokenDecode: Equatable, Sendable {
  /// The session the claims describe — decoded only, never verified: the sample holds no signing key.
  case decoded(UseSmileIDSampleTokenSession)
  /// Names the claim or the structure that failed. Never a value, bar the `api_url` host, which is a public API host.
  case rejected(String)

  public var session: UseSmileIDSampleTokenSession? {
    if case .decoded(let session) = self {
      return session
    }
    return nil
  }

  public var rejection: String? {
    if case .rejected(let reason) = self {
      return reason
    }
    return nil
  }
}

/// Reads the claims a session is made of. **Decoding is not verification:** the sample holds no
/// signing key, so a decoded token is only a claim about itself and a rejection is the one honest
/// response to a token that will not parse.
///
/// The SDK's own decoder is public but its parsed payload is internal, so a host cannot reach the
/// claim through it. Until that accessor widens, this is a documented duplicate of two SDK rules — a
/// field binds iff the claim carries it as a non-empty string, and a consent object binds only when
/// `granted` is boolean `true`.
public enum UseSmileIDSampleTokenDecoder {
  /// Decoded when the segments, the iat/exp pair and the api_url all read; otherwise rejected, naming the first failure.
  public static func decode(_ token: String) -> UseSmileIDSampleTokenDecode {
    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
    let segments = trimmed.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    guard segments.count == Self.segments, segments.allSatisfy(isBase64Url) else {
      return .rejected("A token is three dot-separated base64url segments; this is not.")
    }
    guard let claims = base64Url(segments[1]) else {
      return .rejected("The token's payload segment is not base64url.")
    }
    guard case .obj(let json)? = parseTokenJson(claims) else {
      return .rejected("The token's payload segment is not a JSON object.")
    }
    guard let issuedAt = json.seconds("iat") else {
      return .rejected("The token carries no numeric iat claim.")
    }
    guard let expires = json.seconds("exp") else {
      return .rejected("The token carries no numeric exp claim.")
    }
    guard expires > issuedAt else {
      return .rejected("The token's exp claim is not after its iat claim.")
    }
    // Refused rather than defaulted: a silent sandbox fallback sends a production token to the
    // wrong host and comes back as a 401 that reads like a bad token.
    guard let apiUrl = json.string("api_url"), !apiUrl.isBlank else {
      return .rejected("The token carries no api_url claim, so nothing says which environment it was minted for.")
    }
    guard let environment = UseSmileIDSampleEnvironment.of(apiUrl: apiUrl) else {
      if let host = UseSmileIDSampleEnvironment.apiUrlHost(apiUrl) {
        return .rejected("The token's api_url names \(host), which is not a Smile ID environment.")
      }
      return .rejected("The token's api_url is not a URL, so it names no environment.")
    }
    return .decoded(
      UseSmileIDSampleTokenSession(
        id: handle(trimmed, jti: json.string("jti")),
        token: trimmed,
        issuedAt: Date(timeIntervalSince1970: issuedAt),
        expiresAt: Date(timeIntervalSince1970: expires),
        bindings: json.obj("payload").map(bindings) ?? UseSmileIDSampleTokenBindings(),
        partnerId: json.string("partner_id").flatMap { $0.isBlank ? nil : $0 },
        environment: environment
      )
    )
  }

  /// The session a token describes, or nil. A stored token that no longer decodes is no session.
  public static func session(_ token: String) -> UseSmileIDSampleTokenSession? {
    decode(token).session
  }

  /// A display handle, never a prefix of the credential: the token's own `jti`, else a digest of it.
  private static func handle(_ token: String, jti: String?) -> String {
    if let jti, !jti.isBlank {
      return jti
    }
    return SHA256.hash(data: Data(token.utf8)).prefix(handleBytes).map { String(format: "%02x", $0) }.joined()
  }

  private static func bindings(_ payload: [String: TokenJson]) -> UseSmileIDSampleTokenBindings {
    UseSmileIDSampleTokenBindings(
      givenNames: payload.binds("given_names"),
      lastName: payload.binds("last_name"),
      email: payload.binds("email"),
      phoneNumber: payload.binds("phone_number"),
      consent: payload.obj("consent").flatMap(consent),
      // Blank-checked, unlike the presence flags: these are read as values, and a blank one would win.
      country: payload.string("country").flatMap { $0.isBlank ? nil : $0 },
      idType: payload.string("id_type").flatMap { $0.isBlank ? nil : $0 },
      idNumberReference: payload.string("id_number").flatMap { $0.isBlank ? nil : $0 }
    )
  }

  /// An empty consent object is no consent, and a non-boolean `granted` never counts toward one.
  private static func consent(_ object: [String: TokenJson]) -> UseSmileIDSampleTokenConsent? {
    guard !object.isEmpty else { return nil }
    return UseSmileIDSampleTokenConsent(
      granted: object.boolean("granted") == true ? true : nil,
      grantedAt: object.string("granted_at"),
      noticeLanguage: object.string("notice_language"),
      noticePrivacyPolicyUrl: object.string("notice_privacy_policy_url")
    )
  }

  private static func isBase64Url(_ segment: String) -> Bool {
    !segment.isEmpty && segment.unicodeScalars.allSatisfy { scalar in
      scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_")
    }
  }

  /// Padding-optional: JWT segments are minted without it, and a pasted one may carry it.
  private static func base64Url(_ segment: String) -> String? {
    var base64 = segment.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
    guard let data = Data(base64Encoded: base64) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static let segments = 3
  private static let handleBytes = 4
}

private extension [String: TokenJson] {
  /// A field is token-bound iff the claim carries it as a non-empty string.
  func binds(_ key: String) -> Bool {
    string(key).map { !$0.isEmpty } ?? false
  }
}

extension String? {
  var isBlankOrNil: Bool {
    self?.isBlank ?? true
  }
}
