import Foundation

/// A linked session: the token a run submits under, held as an absolute deadline because a counter
/// restarts at the wrong value after process death. Built only by ``UseSmileIDSampleTokenDecoder``,
/// so a session cannot exist without a token that decodes.
public struct UseSmileIDSampleTokenSession: Equatable, Sendable, CustomStringConvertible {
  /// A display handle — the token's `jti`, else a digest of it. Never a prefix of the credential.
  public let id: String
  public let token: String
  public let issuedAt: Date
  public let expiresAt: Date
  public let bindings: UseSmileIDSampleTokenBindings
  /// The partner the token was minted for, from its own `partner_id` claim. The authority for a
  /// submission's identity: sending a locally configured id alongside a real token is how a signed
  /// request gets a 401. Never logged — a partner id is on this repo's never-commit list.
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

  /// 1 on a fresh session down to 0 on an expired one, over the token's own span, for the nav bar's
  /// ring. The decoder rejects a token whose `exp` is not after its `iat`, so the span is positive by
  /// construction — but this initialiser is public, and a zero span would divide to NaN, which a
  /// clamp passes straight through to the ring.
  public func progress(at now: Date) -> Double {
    let span = max(expiresAt.timeIntervalSince(issuedAt), 0.001)
    return min(max(remaining(at: now) / span, 0), 1)
  }

  /// Redacted: a synthesised description is how a bearer credential reaches a log or a crash report.
  public var description: String {
    "UseSmileIDSampleTokenSession(id=\(id), environment=\(environment.label), expiresAt=\(expiresAt.timeIntervalSince1970))"
  }
}

/// `m:ss`, growing an hours part when the span needs one — an 8h token reads 7:59:12, not 479:12.
/// Floors rather than rounds, so it never shows time that has gone.
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
