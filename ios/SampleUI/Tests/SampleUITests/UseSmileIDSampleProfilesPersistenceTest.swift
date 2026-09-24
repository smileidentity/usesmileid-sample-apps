@testable import SampleUI
import XCTest

/// Profiles survive a restart, and an install updated from a build that never stored them reads as a first launch.
final class UseSmileIDSampleProfilesPersistenceTest: XCTestCase {
  private var rows: UseSmileIDSampleMemorySettingsStorage!

  override func setUp() {
    super.setUp()
    rows = UseSmileIDSampleMemorySettingsStorage()
  }

  func testProfilesWrittenByOneStoreAreReadByTheNext() {
    let profiles = UseSmileIDSampleProfiles(
      [UseSmileIDSampleProfile(id: "p-1", organisation: "Kobo Bank", callbackUrl: "https://kobo.example/hook")]
    )

    makeStore().setProfiles(profiles)

    XCTAssertEqual(makeStore().profiles, profiles)
  }

  func testAStoreHoldingOnlyTheReleasedKeysReadsAsNoProfilesWithItsSettingsIntact() {
    rows.setFlag(.darkMode, true)

    let store = makeStore()

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles())
    XCTAssertTrue(store.settings.darkMode)
  }

  func testAnUnreadableRecordReadsAsNoProfiles() {
    rows.setData("sample_profiles", Data(#"{"version":1,"profiles":["#.utf8))

    XCTAssertEqual(makeStore().profiles, UseSmileIDSampleProfiles())
  }

  func testALaunchArgumentStringCannotSeedProfiles() throws {
    let suite = "UseSmileIDSampleProfilesPersistenceTest"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(#"{"version":1,"profiles":[{"id":"p-1","organisation":"Injected"}]}"#, forKey: "sample_profiles")

    let store = UseSmileIDSampleStore(
      storage: UseSmileIDSampleMemoryStorage(),
      settingsStorage: UseSmileIDSampleDefaultsStorage(defaults: defaults)
    )

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles())
  }

  private func makeStore() -> UseSmileIDSampleStore {
    UseSmileIDSampleStore(storage: UseSmileIDSampleMemoryStorage(), settingsStorage: rows)
  }
}
