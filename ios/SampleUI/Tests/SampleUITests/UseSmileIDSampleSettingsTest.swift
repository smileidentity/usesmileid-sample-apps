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

  func testTheOtherThreeSettingsDoNotDisturbTheCapturePair() {
    let base = UseSmileIDSampleSettings(enhancedSmartSelfie: true)
    for setting in [UseSmileIDSampleSetting.consentStep, .instructionsStep, .previewStep] {
      let changed = base.with(setting, false)
      XCTAssertTrue(changed.enhancedSmartSelfie, "\(setting) disturbed the capture pair")
      XCTAssertFalse(changed.agentMode, "\(setting) disturbed the capture pair")
      XCTAssertFalse(changed[setting])
    }
  }

  func testNormalisedRepairsAStoredStateCarryingBoth() {
    // The pair the SDK refuses: a stored blob predating the mutex can hold it, so the load path repairs it.
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
      consentStep: false,
      instructionsStep: true,
      previewStep: false,
      galleryUpload: true,
      allowSkipBack: true,
      selfieFirst: true
    )
    XCTAssertEqual(
      UseSmileIDSampleSetting.allCases.map { settings[$0] },
      [false, true, false, true, false, true, true, true]
    )
  }

  func testAFreshInstallFollowsTheDevice() {
    XCTAssertEqual(UseSmileIDSampleSettings().appearance, .system)
  }

  func testEachAppearanceResolvesAgainstBothDeviceThemes() {
    let cases: [(UseSmileIDSampleAppearance, Bool, Bool)] = [
      (.system, false, false), (.system, true, true),
      (.light, false, false), (.light, true, false),
      (.dark, false, true), (.dark, true, true)
    ]
    for (appearance, deviceDark, dark) in cases {
      XCTAssertEqual(appearance.isDark(deviceDark: deviceDark), dark, "\(appearance) on deviceDark \(deviceDark)")
    }
  }

  func testTheSystemLabelNamesTheDevicesThemeAndTheOthersNameThemselves() {
    let cases: [(UseSmileIDSampleAppearance, Bool, String)] = [
      (.system, false, "System (Light)"), (.system, true, "System (Dark)"),
      (.light, false, "Light"), (.light, true, "Light"),
      (.dark, false, "Dark"), (.dark, true, "Dark")
    ]
    for (appearance, deviceDark, label) in cases {
      XCTAssertEqual(appearance.label(deviceDark: deviceDark), label, "\(appearance) on deviceDark \(deviceDark)")
    }
  }
}
