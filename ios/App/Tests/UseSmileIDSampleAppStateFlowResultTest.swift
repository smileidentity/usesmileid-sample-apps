import SampleUI
@testable import UseSmileIDSample
import XCTest

/// The scene-storage wrapper around the run: one string out, the same run back, restored once.
@MainActor
final class UseSmileIDSampleAppStateFlowResultTest: XCTestCase {
  private func appState() -> UseSmileIDSampleAppState {
    UseSmileIDSampleAppState(store: UseSmileIDSampleStore(storage: UseSmileIDSampleMemoryStorage()))
  }

  func testARunRoundTripsThroughTheEncodedString() {
    let app = appState()
    app.flowResult.selectScenario(.badRefresh)
    app.flowResult.enterRoute(.shell)
    app.flowResult.recordRefreshCallback()
    app.flowResult.recordResultCallback(status: .failed, jobId: "job_1", error: "2213: authentication failed")

    let restored = appState()
    restored.restoreFlowResult(from: app.encodedFlowResult())
    XCTAssertEqual(restored.flowResult, app.flowResult)
  }

  /// The restore wins once; the drawer's later choice must not be undone by a second appearance.
  func testASecondRestoreIsIgnored() {
    let app = appState()
    var stored = UseSmileIDSampleFlowResult()
    stored.selectScenario(.offlineRetry)
    let encoded = appState().encoded(stored)
    app.restoreFlowResult(from: encoded)
    XCTAssertEqual(app.flowResult.scenario, .offlineRetry)

    app.flowResult.selectScenario(.noCallback)
    app.restoreFlowResult(from: encoded)
    XCTAssertEqual(app.flowResult.scenario, .noCallback, "a second restore overwrote the drawer's choice")
  }

  func testAnUnreadableStringKeepsTheSeededRun() {
    let app = appState()
    app.restoreFlowResult(from: "not json")
    XCTAssertEqual(app.flowResult, UseSmileIDSampleFlowResult())
    XCTAssertFalse(app.encodedFlowResult().isEmpty, "the seed still encodes for the next scene")
  }

  /// The toggle is app state but not part of the run, so it is not in the encoding.
  func testTheCardToggleIsNotEncodedWithTheRun() {
    let app = appState()
    let before = app.encodedFlowResult()
    app.resultCardExpanded = false
    XCTAssertEqual(app.encodedFlowResult(), before)
  }
}

private extension UseSmileIDSampleAppState {
  func encoded(_ result: UseSmileIDSampleFlowResult) -> String {
    flowResult = result
    return encodedFlowResult()
  }
}
