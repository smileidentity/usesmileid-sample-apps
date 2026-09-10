import Foundation

/// A linked session, held as an absolute deadline because a counter restarts wrong after process death.
public struct UseSmileIDSampleTokenSession: Equatable, Sendable, CustomStringConvertible {
  /// A display handle — the token's `jti`, else a digest of it. Never a prefix of the credential.
  public let id: String
  public let token: String
  public let issuedAt: Date
  public let expiresAt: Date
  public let bindings: UseSmileIDSampleTokenBindings
  /// The partner from the token's own claim, never a locally configured id, which is how a signed request gets a 401. Never logged.
  public let partnerId: String?
  /// From the token's own `api_url` claim. Non-nil by construction: the decoder refuses a token it cannot place.
  public let environment: UseSmileIDSampleEnvironment

  public init(
    id: String,
    token: String,
    issuedAt: Date,
    expiresAt: Date,
    bindings: UseSmileIDSampleTokenBindings,
    partnerId: String? = nil,
    environment: UseSmileIDSampleEnvironment
  ) {
    self.id = id
    self.token = token
    self.issuedAt = issuedAt
    self.expiresAt = expiresAt
    self.bindings = bindings
    self.partnerId = partnerId
    self.environment = environment
  }

  public func remaining(at now: Date) -> TimeInterval {
    max(0, expiresAt.timeIntervalSince(now))
  }

  public func hasExpired(at now: Date) -> Bool {
    now >= expiresAt
  }

  /// 1 fresh down to 0 expired, over the token's own span; the zero-span guard is for the public initialiser, since NaN survives a clamp.
  public func progress(at now: Date) -> Double {
    let span = max(expiresAt.timeIntervalSince(issuedAt), 0.001)
    return min(max(remaining(at: now) / span, 0), 1)
  }

  /// Redacted: a synthesised description is how a bearer credential reaches a log or a crash report.
  public var description: String {
    "UseSmileIDSampleTokenSession(id=\(id), environment=\(environment.label), expiresAt=\(expiresAt.timeIntervalSince1970))"
  }
}

/// `m:ss`, growing an hours part when the span needs one (7:59:12, not 479:12); floors, so it never shows time that has gone.
public func useSmileIDSampleCountdown(_ remaining: TimeInterval) -> String {
  let total = Int(max(0, remaining).rounded(.down))
  let hours = total / 3600
  let minutes = (total % 3600) / 60
  let seconds = total % 60
  if hours > 0 {
    return "\(hours):\(padded(minutes)):\(padded(seconds))"
  }
  return "\(minutes):\(padded(seconds))"
}

private func padded(_ value: Int) -> String {
  value < 10 ? "0\(value)" : "\(value)"
}
