/// The flow scenarios the drawer offers, asserted against `spec/scenarios.json` by a unit test.
public enum UseSmileIDSampleScenario: String, CaseIterable, Sendable {
  case normal
  case expiredToken
  case badRefresh
  case noCallback
  case throwingCallback
  case offlineRetry

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .normal: "Normal"
    case .expiredToken: "Expired token"
    case .badRefresh: "Refresh fails"
    case .noCallback: "No result callback"
    case .throwingCallback: "Throwing callback"
    case .offlineRetry: "Offline then retry"
    }
  }

  public var description: String {
    switch self {
    case .normal: "Happy path with valid sandbox credentials."
    case .expiredToken: "Token is valid but expired, so the SDK must refresh before it can submit."
    case .badRefresh: "Refresh returns an unusable token, so the failure path must surface."
    case .noCallback: "Host provides no result callback; the SDK must not crash or hang."
    case .throwingCallback: "Host callback throws; it must not corrupt SDK state."
    case .offlineRetry: "Submission starts with no connectivity, then it returns."
    }
  }

  /// Restored identifiers fall back rather than throw, so a retired scenario cannot crash a restore.
  public init(id: String?) {
    self = UseSmileIDSampleScenario(rawValue: id ?? "") ?? .normal
  }
}

/// Theme scenarios apply on top of any flow scenario, through the SDK's public theme override.
public enum UseSmileIDSampleThemeScenario: String, CaseIterable, Sendable {
  case brandDefault
  case clashingHost
  case partnerOverride

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .brandDefault: "Brand default"
    case .clashingHost: "Clashing host"
    case .partnerOverride: "Partner override"
    }
  }

  public var description: String {
    switch self {
    case .brandDefault: "Ship state: Smile ID branding, light or dark per the Settings switch."
    case .clashingHost: "A deliberately distant host theme, to expose host-versus-SDK collisions."
    case .partnerOverride: "A plausible partner palette through the same public override."
    }
  }

  public init(id: String?) {
    self = UseSmileIDSampleThemeScenario(rawValue: id ?? "") ?? .brandDefault
  }
}
