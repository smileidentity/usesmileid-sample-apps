/// Cancelled and failed stay separate: a screenshot cannot tell a user backing out from a failure.
public enum UseSmileIDSampleFlowStatus: String, CaseIterable, Sendable {
  case idle
  case running
  case succeeded
  case cancelled
  case failed

  public var id: String {
    rawValue
  }

  public init(id: String?) {
    self = UseSmileIDSampleFlowStatus(rawValue: id ?? "") ?? .idle
  }
}

/// A snapshot of what the SDK did, mirroring `spec/result-card.schema.json` field for field.
public struct UseSmileIDSampleResult: Equatable, Sendable {
  public var activeScenario: UseSmileIDSampleScenario
  public var activeTheme: UseSmileIDSampleThemeScenario
  public var route: UseSmileIDSampleFlowRoute
  /// Where the run submitted, from its token. With the chip gone this is the only surface that proves it.
  public var environment: UseSmileIDSampleEnvironment
  public var jobStatus: UseSmileIDSampleFlowStatus
  public var resultCallbackCount: Int
  public var refreshCallbackCount: Int
  public var jobId: String?
  public var userId: String?
  public var lastError: String?
  /// Always nil on iOS: the published package exposes no runtime accessor, and the pin must not stand in.
  public var sdkVersion: String?

  public init(
    activeScenario: UseSmileIDSampleScenario,
    activeTheme: UseSmileIDSampleThemeScenario,
    route: UseSmileIDSampleFlowRoute,
    environment: UseSmileIDSampleEnvironment,
    jobStatus: UseSmileIDSampleFlowStatus,
    resultCallbackCount: Int,
    refreshCallbackCount: Int,
    jobId: String? = nil,
    userId: String? = nil,
    lastError: String? = nil,
    sdkVersion: String? = nil
  ) {
    self.activeScenario = activeScenario
    self.activeTheme = activeTheme
    self.route = route
    self.environment = environment
    self.jobStatus = jobStatus
    self.resultCallbackCount = resultCallbackCount
    self.refreshCallbackCount = refreshCallbackCount
    self.jobId = jobId
    self.userId = userId
    self.lastError = lastError
    self.sdkVersion = sdkVersion
  }

  public var inFlight: Bool {
    jobStatus == .running
  }
}
