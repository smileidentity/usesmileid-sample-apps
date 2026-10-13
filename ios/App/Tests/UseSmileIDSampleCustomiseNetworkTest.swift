import SampleUI
import UseSmileID
@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleCustomiseNetworkTest: XCTestCase {
  private enum Recording: UseSmileIDSampleShellExtending {
    static var customised: [UseSmileIDSampleProduct] = []

    static func customiseNetwork(_: UseSmileIDNetworkBuilder, product: UseSmileIDSampleProduct) {
      customised.append(product)
    }
  }

  func testTheExtensionCustomisesTheNetworkTheShellConfiguredForTheProduct() {
    Recording.customised = []
    let snapshot = FlowLaunchSnapshot(
      product: .smartSelfieEnrollment,
      route: .fullscreen,
      partnerId: "0000",
      partnerName: "UpTech Finance",
      callbackUrl: "",
      session: nil
    )
    useSmileIDSampleNetwork(UseSmileIDNetworkBuilder(), snapshot, onTokenRefreshed: {}, extension: Recording.self)
    XCTAssertEqual(Recording.customised, [.smartSelfieEnrollment])
  }
}
