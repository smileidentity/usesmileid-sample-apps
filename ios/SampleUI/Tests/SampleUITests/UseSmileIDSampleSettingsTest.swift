@testable import SampleUI
import XCTest

final class UseSmileIDSampleSettingsTest: XCTestCase {
  func testTurningAgentModeOnTurnsEnhancedLivenessOff() {
    let settings = UseSmileIDSampleSettings(enhancedSmartSelfie: true).with(.agentMode, true)
    XCTAssertTrue(settings.agentMode)
    XCTAssertFalse(settings.enhancedSmartSelfie)
  }

  func testTurningEnhancedLivenessOnTurnsAgentModeOff() {
    let settings = UseSmileIDSampleSettings(enhancedSmartSelfie: false, agentMode: true)
      .with(.enhancedSmartSelfie, true)
    XCTAssertTrue(settings.enhancedSmartSelfie)
    XCTAssertFalse(settings.agentMode)
  }

  func testTurningEitherOffLeavesTheOtherAlone() {
    let settings = UseSmileIDSampleSettings(enhancedSmartSelfie: true).with(.enhancedSmartSelfie, false)
    XCTAssertFalse(settings.enhancedSmartSelfie)
    XCTAssertFalse(settings.agentMode)
  }

  func testTheOtherFourSettingsDoNotDisturbTheCapturePair() {
    let base = UseSmileIDSampleSettings(enhancedSmartSelfie: true)
    for setting in [UseSmileIDSampleSetting.darkMode, .consentStep, .instructionsStep, .previewStep] {
      let changed = base.with(setting, false)
      XCTAssertTrue(changed.enhancedSmartSelfie, "\(setting) disturbed the capture pair")
      XCTAssertFalse(changed.agentMode, "\(setting) disturbed the capture pair")
      XCTAssertFalse(changed[setting])
    }
  }

  func testNormalisedRepairsAStoredStateCarryingBoth() {
    // The pair the SDK refuses. A stored blob predating the mutex can hold it, so the load path
    // repairs rather than rejects — the initialiser deliberately does not enforce this.
    var stored = UseSmileIDSampleSettings()
    stored.agentMode = true
    stored.enhancedSmartSelfie = true
    let repaired = stored.normalised()
    XCTAssertTrue(repaired.agentMode)
    XCTAssertFalse(repaired.enhancedSmartSelfie)
  }

  func testNormalisedLeavesAValidStateUntouched() {
    let valid = UseSmileIDSampleSettings(enhancedSmartSelfie: true)
    XCTAssertEqual(valid.normalised(), valid)
  }

  func testSubscriptReadsEveryRow() {
    let settings = UseSmileIDSampleSettings(
      enhancedSmartSelfie: false,
      agentMode: true,
      darkMode: true,
      consentStep: false,
      instructionsStep: true,
      previewStep: false
    )
    XCTAssertEqual(
      UseSmileIDSampleSetting.allCases.map { settings[$0] },
      [false, true, true, false, true, false]
    )
  }
}
