@testable import SampleUI
import XCTest

final class UseSmileIDSampleFlowResultTest: XCTestCase {
  func testAFreshRunHasCountedNothing() {
    let result = UseSmileIDSampleFlowResult().snapshot
    XCTAssertEqual(result.resultCallbackCount, 0)
    XCTAssertEqual(result.refreshCallbackCount, 0)
    XCTAssertEqual(result.jobStatus, .idle)
  }

  func testEachCallbackCountsOnce() {
    var flow = UseSmileIDSampleFlowResult()
    flow.recordRefreshCallback()
    flow.recordRefreshCallback()
    flow.recordResultCallback(status: .succeeded, jobId: "job_1", userId: "user_1")

    XCTAssertEqual(flow.resultCallbackCount, 1)
    XCTAssertEqual(flow.refreshCallbackCount, 2)
    XCTAssertEqual(flow.jobId, "job_1")
    XCTAssertEqual(flow.userId, "user_1")
  }

  func testASecondResultCallbackIsVisibleRatherThanSwallowed() {
    var flow = UseSmileIDSampleFlowResult()
    flow.recordResultCallback(status: .succeeded, jobId: "job_1")
    flow.recordResultCallback(status: .succeeded, jobId: "job_1")
    XCTAssertEqual(flow.resultCallbackCount, 2)
  }

  func testStartingARunClearsThePreviousOutcomeAndBothCounts() {
    var flow = UseSmileIDSampleFlowResult()
    flow.recordRefreshCallback()
    flow.recordResultCallback(status: .failed, error: "2213: authentication failed")

    flow.startFlow(environment: .production)

    XCTAssertEqual(flow.status, .running)
    XCTAssertEqual(flow.environment, .production, "the run's own environment, from its snapshot")
    XCTAssertEqual(flow.resultCallbackCount, 0)
    XCTAssertEqual(flow.refreshCallbackCount, 0)
    XCTAssertNil(flow.lastError)
    XCTAssertNil(flow.jobId)
  }

  func testRecreationPreservesTheCountsAndTheOutcome() {
    var flow = UseSmileIDSampleFlowResult(scenario: .badRefresh)
    flow.enterRoute(.shell)
    flow.recordRefreshCallback()
    flow.recordResultCallback(status: .failed, error: "2213: authentication failed")

    XCTAssertEqual(UseSmileIDSampleFlowResult(saved: flow.saved).snapshot, flow.snapshot)
  }

  func testAScenarioThisBuildNoLongerHasRestoresAsTheDefault() {
    let restored = UseSmileIDSampleFlowResult(
      saved: ["retiredScenario", "brandDefault", "fullscreen", "sandbox", "idle", "", "", "", "0", "0"]
    )
    XCTAssertEqual(restored.scenario, .normal)
  }

  func testAnUnreadableEnvironmentRestoresAsSandboxRatherThanTakingTheAppDown() {
    let restored = UseSmileIDSampleFlowResult(
      saved: ["normal", "brandDefault", "fullscreen", "somewhere-else", "idle", "", "", "", "0", "0"]
    )
    XCTAssertEqual(restored.environment, .sandbox)
  }

  func testACountThatDidNotRoundTripRestoresAsZero() {
    let restored = UseSmileIDSampleFlowResult(
      saved: ["normal", "brandDefault", "fullscreen", "production", "idle", "", "", "", "", "not-a-number"]
    )
    XCTAssertEqual(restored.resultCallbackCount, 0)
    XCTAssertEqual(restored.refreshCallbackCount, 0)
  }

  /// A blocked run is a failure the SDK never saw, so the result count must not move.
  func testABlockedRunFailsWithoutCountingAResultCallback() {
    var flow = UseSmileIDSampleFlowResult()
    flow.recordBlocked(reason: "Scan a token first", environment: .production)
    XCTAssertEqual(flow.status, .failed)
    XCTAssertEqual(flow.lastError, "Scan a token first")
    XCTAssertEqual(flow.environment, .production)
    XCTAssertEqual(flow.resultCallbackCount, 0)
  }
}
