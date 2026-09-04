@testable import SampleUI

/// The card's five states, with the values the Compose goldens carry.
enum UseSmileIDSampleResultFixtures {
  static let idle = UseSmileIDSampleResult(
    activeScenario: .normal,
    activeTheme: .brandDefault,
    route: .fullscreen,
    environment: .sandbox,
    jobStatus: .idle,
    resultCallbackCount: 0,
    refreshCallbackCount: 0
  )

  static let running: UseSmileIDSampleResult = {
    var result = idle
    result.route = .shell
    result.jobStatus = .running
    return result
  }()

  static let succeeded: UseSmileIDSampleResult = {
    var result = idle
    result.jobStatus = .succeeded
    result.jobId = "job_9f3a2c7104e8"
    result.userId = "user_5b1ec4d2"
    result.resultCallbackCount = 1
    return result
  }()

  static let cancelled: UseSmileIDSampleResult = {
    var result = idle
    result.jobStatus = .cancelled
    result.resultCallbackCount = 1
    return result
  }()

  static let failed: UseSmileIDSampleResult = {
    var result = idle
    result.activeScenario = .badRefresh
    result.jobStatus = .failed
    result.resultCallbackCount = 1
    result.refreshCallbackCount = 2
    result.lastError = "2213: authentication failed \u{2014} refresh returned an expired token"
    return result
  }()
}
