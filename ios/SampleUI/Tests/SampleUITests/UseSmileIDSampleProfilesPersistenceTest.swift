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

  func testALaunchArgumentCannotSeedProfiles() throws {
    let key = "sample_profiles"
    let injected = try XCTUnwrap(UseSmileIDSampleProfilesCodec.encode(UseSmileIDSampleProfiles([
      UseSmileIDSampleProfile(id: "p-1", organisation: "Injected")
    ])))
    let arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
    defer { UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain) }
    // What `-sample_profiles <hex>` becomes: data in the argument domain, which reads shadow.
    UserDefaults.standard.setVolatileDomain(arguments.merging([key: injected]) { $1 }, forName: UserDefaults.argumentDomain)
    XCTAssertEqual(UserDefaults.standard.data(forKey: key), injected, "the argument did not reach the defaults")

    let store = UseSmileIDSampleStore(
      storage: UseSmileIDSampleMemoryStorage(),
      settingsStorage: UseSmileIDSampleDefaultsStorage(defaults: .standard)
    )

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles())
  }

  private func makeStore() -> UseSmileIDSampleStore {
    UseSmileIDSampleStore(storage: UseSmileIDSampleMemoryStorage(), settingsStorage: rows)
  }
}
