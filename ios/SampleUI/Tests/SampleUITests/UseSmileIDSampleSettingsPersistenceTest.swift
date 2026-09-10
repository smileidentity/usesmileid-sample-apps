@testable import SampleUI
import XCTest

final class UseSmileIDSampleSettingsPersistenceTest: XCTestCase {
  private var rows: UseSmileIDSampleMemorySettingsStorage!

  override func setUp() {
    super.setUp()
    rows = UseSmileIDSampleMemorySettingsStorage()
  }

  func testTheMutexWritesBothRowsNotJustTheOneThatWasTapped() {
    let store = makeStore()

    let written = store.setSetting(.agentMode, true)

    XCTAssertTrue(written.agentMode)
    XCTAssertFalse(written.enhancedSmartSelfie, "agent mode must take enhanced liveness with it")
    XCTAssertEqual(rows.flag(.enhancedSmartSelfie), false)
    XCTAssertEqual(store.settings, written, "the store must read back its own write")
  }

  func testARowThatDidNotMoveIsNeverWritten() {
    makeStore().setSetting(.consentStep, false)

    XCTAssertEqual(rows.flag(.consentStep), false)
    // Writing all six would freeze today's defaults onto the device.
    XCTAssertNil(rows.flag(.previewStep))
    XCTAssertNil(rows.flag(.agentMode))
  }

  func testSettingARowToTheValueItAlreadyHoldsWritesNothing() {
    makeStore().setSetting(.previewStep, true)

    XCTAssertNil(rows.flag(.previewStep))
  }

  func testAnAbsentRowReadsAsTodaysDefault() {
    XCTAssertEqual(makeStore().settings, UseSmileIDSampleSettings())

    makeStore().setSetting(.darkMode, true)

    XCTAssertEqual(makeStore().settings, UseSmileIDSampleSettings(darkMode: true))
  }

  func testAStoredPairTheSdkRefusesIsNormalisedOnRead() {
    rows.setFlag(.agentMode, true)
    rows.setFlag(.enhancedSmartSelfie, true)

    let settings = makeStore().settings

    XCTAssertTrue(settings.agentMode)
    XCTAssertFalse(settings.enhancedSmartSelfie, "the pair the SDK refuses must be repaired on read")
  }

  func testEveryRowSurvivesARoundTripUnderItsOwnKey() {
    let store = makeStore()
    for setting in UseSmileIDSampleSetting.allCases {
      store.setSetting(setting, !UseSmileIDSampleSettings()[setting])
    }

    // Read back through a second store, all six at once: two rows sharing a key pass row by row and fail here.
    XCTAssertEqual(
      makeStore().settings,
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

  func testTheKeysAreTheAndroidStoresOwn() {
    XCTAssertEqual(UseSmileIDSampleSetting.allCases.map(\.storageKey), Self.keys)
  }

  func testAValueGivenAtLaunchSeedsTheReadAndPersistsNothing() throws {
    let suite = "usesmileid_sample_settings_test"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let previous = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    defer { Self.reset(defaults, suite, previous) }
    defaults.setVolatileDomain(
      [UseSmileIDSampleSetting.agentMode.storageKey: "true", UseSmileIDSampleSetting.enhancedSmartSelfie.storageKey: "false"],
      forName: UserDefaults.argumentDomain
    )

    let launched = makeStore(defaults)

    XCTAssertTrue(launched.settings.agentMode, "a launch value must seed the read")
    XCTAssertFalse(launched.settings.enhancedSmartSelfie)
    XCTAssertNil(
      defaults.persistentDomain(forName: suite)?[UseSmileIDSampleSetting.agentMode.storageKey],
      "the seed is volatile: a launch must persist nothing"
    )
  }

  func testALaunchValueDoesNotShadowALaterWriteWhichIsWhyTheRowsAreReadOnce() throws {
    let suite = "usesmileid_sample_settings_shadow_test"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let previous = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    defer { Self.reset(defaults, suite, previous) }
    let key = UseSmileIDSampleSetting.darkMode.storageKey
    defaults.setVolatileDomain([key: "true"], forName: UserDefaults.argumentDomain)
    let launched = makeStore(defaults)

    launched.setSetting(.darkMode, false)

    XCTAssertFalse(launched.settings.darkMode, "the store must answer with its own write")
    XCTAssertEqual(defaults.persistentDomain(forName: suite)?[key] as? Bool, false)
    // Measured: the argument domain outranks the persistent one, so a re-read would still say true.
    XCTAssertTrue(makeStore(defaults).settings.darkMode)
  }

  private func makeStore(_ defaults: UserDefaults? = nil) -> UseSmileIDSampleStore {
    UseSmileIDSampleStore(
      storage: UseSmileIDSampleMemoryStorage(),
      settingsStorage: defaults.map(UseSmileIDSampleDefaultsStorage.init) ?? rows
    )
  }

  private static func reset(_ defaults: UserDefaults, _ suite: String, _ previous: [String: Any]) {
    defaults.setVolatileDomain(previous, forName: UserDefaults.argumentDomain)
    defaults.removePersistentDomain(forName: suite)
  }

  private static let keys = [
    "enhanced_smart_selfie", "agent_mode", "dark_mode", "consent_step", "instructions_step", "preview_step"
  ]
}
