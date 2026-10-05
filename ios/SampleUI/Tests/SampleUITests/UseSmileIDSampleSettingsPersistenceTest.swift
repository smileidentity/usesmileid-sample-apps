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

    makeStore().setSetting(.agentMode, true)

    XCTAssertEqual(makeStore().settings, UseSmileIDSampleSettings(enhancedSmartSelfie: false, agentMode: true))
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

    // Read back through a second store, every row at once: two rows sharing a key pass row by row and fail here.
    XCTAssertEqual(
      makeStore().settings,
      UseSmileIDSampleSettings(
        enhancedSmartSelfie: false,
        agentMode: true,
        consentStep: false,
        instructionsStep: false,
        previewStep: false,
        galleryUpload: true,
        allowSkipBack: true,
        selfieFirst: true
      )
    )
    XCTAssertEqual(Self.keys.count, UseSmileIDSampleSetting.allCases.count, "a row was added with no key here")
  }

  func testCaptureModeSurvivesARoundTripAndAnAbsentValueIsTheDefault() {
    XCTAssertEqual(makeStore().settings.captureMode, .autoWithFallback)
    makeStore().setCaptureMode(.manual)
    XCTAssertEqual(makeStore().settings.captureMode, .manual)
  }

  func testNoStoredAppearanceFollowsTheDevice() {
    XCTAssertEqual(makeStore().settings.appearance, .system)
  }

  func testTheReleasedDarkModeSwitchTurnedOnReadsAsDark() {
    rows.setFlag("dark_mode", true)
    XCTAssertEqual(makeStore().settings.appearance, .dark)
  }

  /// False was also the switch's default, so it proves no one chose Light.
  func testTheReleasedDarkModeSwitchTurnedOffFollowsTheDevice() {
    rows.setFlag("dark_mode", false)
    XCTAssertEqual(makeStore().settings.appearance, .system)
  }

  /// Also the state a crash between the two writes leaves behind.
  func testAStoredAppearanceWinsOverTheReleasedSwitch() {
    rows.setString("appearance", "light")
    rows.setFlag("dark_mode", true)
    XCTAssertEqual(makeStore().settings.appearance, .light)
  }

  func testAnUnknownAppearanceFollowsTheDevice() {
    rows.setString("appearance", "sepia")
    XCTAssertEqual(makeStore().settings.appearance, .system)
  }

  func testChoosingAnAppearanceStoresItsIdAndRetiresTheReleasedSwitch() {
    rows.setFlag("dark_mode", true)
    let store = makeStore()

    store.setAppearance(.light)

    XCTAssertEqual(store.settings.appearance, .light)
    XCTAssertEqual(rows.string("appearance"), "light")
    XCTAssertNil(rows.flag("dark_mode"))
    XCTAssertEqual(makeStore().settings.appearance, .light)
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
    let key = "appearance"
    defaults.setVolatileDomain([key: "light"], forName: UserDefaults.argumentDomain)
    let launched = makeStore(defaults)
    XCTAssertEqual(launched.settings.appearance, .light, "`-appearance light` must seed the read, which `data(_:)` would refuse")

    launched.setAppearance(.dark)

    XCTAssertEqual(launched.settings.appearance, .dark, "the store must answer with its own write")
    XCTAssertEqual(defaults.persistentDomain(forName: suite)?[key] as? String, "dark")
    // Measured: the argument domain outranks the persistent one, so a re-read would still say light.
    XCTAssertEqual(makeStore(defaults).settings.appearance, .light)
  }

  func testTheArgumentDomainReachesAStringButNeverData() throws {
    let suite = "usesmileid_sample_settings_string_test"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let previous = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    defer { Self.reset(defaults, suite, previous) }
    defaults.setVolatileDomain(["appearance": "dark", "capture_mode": "manual"], forName: UserDefaults.argumentDomain)

    let storage = UseSmileIDSampleDefaultsStorage(defaults: defaults)

    XCTAssertEqual(storage.string("appearance"), "dark")
    XCTAssertNil(storage.data("capture_mode"), "a launch argument must never seed data")
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
    "enhanced_smart_selfie", "agent_mode", "consent_step", "instructions_step", "preview_step",
    "gallery_upload", "allow_skip_back", "selfie_first"
  ]
}
