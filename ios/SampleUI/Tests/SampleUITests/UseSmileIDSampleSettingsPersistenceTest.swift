@testable import SampleUI
import XCTest

final class UseSmileIDSampleSettingsPersistenceTest: XCTestCase {
  private var rows: UseSmileIDSampleMemorySettingsStorage!
  private var store: UseSmileIDSampleStore!

  override func setUp() {
    super.setUp()
    rows = UseSmileIDSampleMemorySettingsStorage()
    store = UseSmileIDSampleStore(storage: UseSmileIDSampleMemoryStorage(), settingsStorage: rows)
  }

  func testTheMutexWritesBothRowsNotJustTheOneThatWasTapped() {
    let written = store.setSetting(.agentMode, true)

    XCTAssertTrue(written.agentMode)
    XCTAssertFalse(written.enhancedSmartSelfie, "agent mode must take enhanced liveness with it")
    XCTAssertEqual(rows.flag(Self.enhancedSmartSelfie), false)
    XCTAssertEqual(store.settings, written, "the returned settings must be the stored ones")
  }

  func testARowThatDidNotMoveIsNeverWritten() {
    store.setSetting(.consentStep, false)

    XCTAssertEqual(rows.flag(Self.consentStep), false)
    // Writing all six would freeze today's defaults onto the device.
    XCTAssertNil(rows.flag(Self.previewStep))
    XCTAssertNil(rows.flag(Self.agentMode))
  }

  func testSettingARowToTheValueItAlreadyHoldsWritesNothing() {
    store.setSetting(.previewStep, true)

    XCTAssertNil(rows.flag(Self.previewStep))
  }

  func testAnAbsentRowReadsAsTodaysDefault() {
    XCTAssertEqual(store.settings, UseSmileIDSampleSettings())

    store.setSetting(.darkMode, true)

    XCTAssertEqual(store.settings, UseSmileIDSampleSettings(darkMode: true))
  }

  func testAStoredPairTheSdkRefusesIsNormalisedOnRead() {
    rows.setFlag(Self.agentMode, true)
    rows.setFlag(Self.enhancedSmartSelfie, true)

    XCTAssertTrue(store.settings.agentMode)
    XCTAssertFalse(store.settings.enhancedSmartSelfie, "the pair the SDK refuses must be repaired on read")
  }

  func testEveryRowSurvivesARoundTripUnderItsOwnKey() {
    for setting in UseSmileIDSampleSetting.allCases {
      store.setSetting(setting, !UseSmileIDSampleSettings()[setting])
    }

    // All six read back at once: two rows sharing a key would pass row by row and fail here.
    XCTAssertEqual(
      store.settings,
      UseSmileIDSampleSettings(
        enhancedSmartSelfie: false,
        agentMode: true,
        darkMode: true,
        consentStep: false,
        instructionsStep: false,
        previewStep: false
      )
    )
    XCTAssertEqual(Self.keys.count, UseSmileIDSampleSetting.allCases.count, "a row was added with no key here")
  }

  func testAValueGivenAtLaunchSeedsTheReadAndPersistsNothing() throws {
    let suite = "usesmileid_sample_settings_test"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let previous = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    defer {
      defaults.setVolatileDomain(previous, forName: UserDefaults.argumentDomain)
      defaults.removePersistentDomain(forName: suite)
    }
    let launched = UseSmileIDSampleStore(
      storage: UseSmileIDSampleMemoryStorage(),
      settingsStorage: UseSmileIDSampleDefaultsStorage(defaults: defaults)
    )
    defaults.setVolatileDomain([Self.agentMode: "true", Self.enhancedSmartSelfie: "false"], forName: UserDefaults.argumentDomain)

    XCTAssertTrue(launched.settings.agentMode, "a launch value must seed the read")
    XCTAssertFalse(launched.settings.enhancedSmartSelfie)
    XCTAssertNil(
      defaults.persistentDomain(forName: suite)?[Self.agentMode],
      "the seed is volatile: a launch must persist nothing"
    )
  }

  func testAWriteIsShadowedByALaunchValueWhichIsWhyTheStoreReturnsWhatItWrote() throws {
    let suite = "usesmileid_sample_settings_shadow_test"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let previous = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    defer {
      defaults.setVolatileDomain(previous, forName: UserDefaults.argumentDomain)
      defaults.removePersistentDomain(forName: suite)
    }
    let launched = UseSmileIDSampleStore(
      storage: UseSmileIDSampleMemoryStorage(),
      settingsStorage: UseSmileIDSampleDefaultsStorage(defaults: defaults)
    )
    defaults.setVolatileDomain([Self.darkMode: "true"], forName: UserDefaults.argumentDomain)

    let written = launched.setSetting(.darkMode, false)

    XCTAssertFalse(written.darkMode, "the caller must see what was written")
    XCTAssertTrue(launched.settings.darkMode, "the argument domain outranks the write for this launch")
    XCTAssertEqual(defaults.persistentDomain(forName: suite)?[Self.darkMode] as? Bool, false)
  }

  private static let enhancedSmartSelfie = "enhanced_smart_selfie"
  private static let agentMode = "agent_mode"
  private static let darkMode = "dark_mode"
  private static let consentStep = "consent_step"
  private static let instructionsStep = "instructions_step"
  private static let previewStep = "preview_step"

  private static let keys = [
    enhancedSmartSelfie, agentMode, darkMode, consentStep, instructionsStep, previewStep
  ]
}
