/// What the hosted flow reported, and the run it belongs to; the card renders its `snapshot`.
///
/// What survives what (port-patterns §3 rule 6). Every field here is held by the app state, so it
/// survives rotation and a tab switch, and the shell mirrors the whole value into scene storage, so
/// a scene the system killed restores the run's outcome and both counts — a count that reset on
/// recreation would swallow the second call it exists to catch. Nothing here is ever written to
/// UserDefaults, the Keychain or disk by the app: a launch the person or a test starts is a fresh
/// run, seeded from the launch arguments, because a persisted count would carry one run's callbacks
/// into the next and the exactly-once claim with it.
public struct UseSmileIDSampleFlowResult: Equatable, Sendable {
  public private(set) var scenario: UseSmileIDSampleScenario
  public private(set) var theme: UseSmileIDSampleThemeScenario
  public private(set) var route: UseSmileIDSampleFlowRoute
  /// Recorded from the run's own snapshot, never re-read: sandbox until a run has said otherwise.
  public private(set) var environment: UseSmileIDSampleEnvironment
  public private(set) var status: UseSmileIDSampleFlowStatus
  public private(set) var jobId: String?
  public private(set) var userId: String?
  public private(set) var lastError: String?
  public private(set) var resultCallbackCount: Int
  public private(set) var refreshCallbackCount: Int

  public init(
    scenario: UseSmileIDSampleScenario = .normal,
    theme: UseSmileIDSampleThemeScenario = .brandDefault,
    route: UseSmileIDSampleFlowRoute = .fullscreen,
    environment: UseSmileIDSampleEnvironment = .sandbox,
    status: UseSmileIDSampleFlowStatus = .idle,
    jobId: String? = nil,
    userId: String? = nil,
    lastError: String? = nil,
    resultCallbackCount: Int = 0,
    refreshCallbackCount: Int = 0
  ) {
    self.scenario = scenario
    self.theme = theme
    self.route = route
    self.environment = environment
    self.status = status
    self.jobId = jobId
    self.userId = userId
    self.lastError = lastError
    self.resultCallbackCount = resultCallbackCount
    self.refreshCallbackCount = refreshCallbackCount
  }

  public var snapshot: UseSmileIDSampleResult {
    UseSmileIDSampleResult(
      activeScenario: scenario,
      activeTheme: theme,
      route: route,
      environment: environment,
      jobStatus: status,
      resultCallbackCount: resultCallbackCount,
      refreshCallbackCount: refreshCallbackCount,
      jobId: jobId,
      userId: userId,
      lastError: lastError
    )
  }

  public mutating func selectScenario(_ value: UseSmileIDSampleScenario) {
    scenario = value
  }

  public mutating func selectTheme(_ value: UseSmileIDSampleThemeScenario) {
    theme = value
  }

  public mutating func enterRoute(_ value: UseSmileIDSampleFlowRoute) {
    route = value
  }

  /// Both counts reset here, so "exactly once" is asserted per run rather than per app launch.
  public mutating func startFlow(environment: UseSmileIDSampleEnvironment) {
    self.environment = environment
    status = .running
    jobId = nil
    userId = nil
    lastError = nil
    resultCallbackCount = 0
    refreshCallbackCount = 0
  }

  /// `userId` must be what the server returned; a local placeholder invalidates every run after it.
  public mutating func recordResultCallback(
    status: UseSmileIDSampleFlowStatus,
    jobId: String? = nil,
    userId: String? = nil,
    error: String? = nil
  ) {
    resultCallbackCount += 1
    self.status = status
    self.jobId = jobId
    self.userId = userId
    lastError = error
  }

  /// The gate refused the run, so the SDK never mounted. Not counted as a result callback.
  public mutating func recordBlocked(reason: String, environment: UseSmileIDSampleEnvironment) {
    self.environment = environment
    status = .failed
    jobId = nil
    userId = nil
    lastError = reason
  }

  public mutating func recordRefreshCallback() {
    refreshCallbackCount += 1
  }

  /// The ten fields as strings in a fixed order, the shape scene storage keeps.
  public var saved: [String] {
    [
      scenario.id, theme.id, route.id, environment.id, status.id,
      jobId ?? "", userId ?? "", lastError ?? "",
      String(resultCallbackCount), String(refreshCallbackCount)
    ]
  }

  /// Read defensively: this runs on a restore, where a throw takes the app down.
  public init(saved: [String]) {
    func field(_ index: Int) -> String {
      index < saved.count ? saved[index] : ""
    }
    self.init(
      scenario: UseSmileIDSampleScenario(id: field(0)),
      theme: UseSmileIDSampleThemeScenario(id: field(1)),
      route: UseSmileIDSampleFlowRoute(id: field(2)),
      environment: UseSmileIDSampleEnvironment(rawValue: field(3)) ?? .sandbox,
      status: UseSmileIDSampleFlowStatus(id: field(4)),
      jobId: field(5).isEmpty ? nil : field(5),
      userId: field(6).isEmpty ? nil : field(6),
      lastError: field(7).isEmpty ? nil : field(7),
      resultCallbackCount: Int(field(8)) ?? 0,
      refreshCallbackCount: Int(field(9)) ?? 0
    )
  }
}
