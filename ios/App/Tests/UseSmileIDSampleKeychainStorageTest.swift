import SampleUI
import XCTest

/// Hosted by the app on purpose: the Keychain answers to a process with an application identity, and an
/// unhosted test bundle has none, so the adapter can only be proven where the app will run it.
final class UseSmileIDSampleKeychainStorageTest: XCTestCase {
  private let keychain = UseSmileIDSampleKeychainStorage(service: "usesmileid_sample_test")

  override func tearDown() {
    keychain.write(nil)
    super.tearDown()
  }

  func testTheAdapterRoundTripsReplacesAndDeletes() {
    keychain.write(nil)
    XCTAssertNil(keychain.read())
    keychain.write(Data("first".utf8))
    XCTAssertEqual(keychain.read(), Data("first".utf8))
    keychain.write(Data("second".utf8))
    XCTAssertEqual(keychain.read(), Data("second".utf8), "a second write must replace, not add")
    keychain.write(nil)
    XCTAssertNil(keychain.read())
  }

  /// The service is the isolation: the app's own item under the default service is never touched by this test.
  func testTwoServicesHoldTwoItems() {
    let other = UseSmileIDSampleKeychainStorage(service: "usesmileid_sample_test_other")
    defer { other.write(nil) }
    keychain.write(Data("mine".utf8))
    other.write(Data("theirs".utf8))
    XCTAssertEqual(keychain.read(), Data("mine".utf8))
    XCTAssertEqual(other.read(), Data("theirs".utf8))
  }
}
