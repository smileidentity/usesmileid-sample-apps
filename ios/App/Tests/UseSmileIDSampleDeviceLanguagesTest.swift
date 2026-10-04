@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleDeviceLanguagesTest: XCTestCase {
  private var defaults: UserDefaults!
  private let suite = "UseSmileIDSampleDeviceLanguagesTest"

  override func setUp() {
    super.setUp()
    defaults = UserDefaults(suiteName: suite)
    defaults.removePersistentDomain(forName: suite)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suite)
    super.tearDown()
  }

  func testALaunchWithoutAnOverrideRecordsTheDevicesLanguages() {
    XCTAssertEqual(UseSmileIDSampleAppState.deviceLanguages(in: defaults), Locale.preferredLanguages)
    XCTAssertEqual(defaults.stringArray(forKey: "device_languages"), Locale.preferredLanguages)
  }

  func testWhileTheAppHasItsOwnLanguageTheRecordedListStandsIn() throws {
    let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier)
    let previous = UserDefaults.standard.persistentDomain(forName: bundle)
    defer { UserDefaults.standard.setPersistentDomain(previous ?? [:], forName: bundle) }
    var domain = previous ?? [:]
    domain["AppleLanguages"] = ["fr"]
    domain["device_languages"] = ["sw-KE", "en-KE"]
    UserDefaults.standard.setPersistentDomain(domain, forName: bundle)

    XCTAssertEqual(UseSmileIDSampleAppState.deviceLanguages(in: .standard), ["sw-KE", "en-KE"])
  }
}
