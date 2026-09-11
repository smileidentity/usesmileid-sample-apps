@testable import SampleUI
import UIKit
import XCTest

final class UseSmileIDSampleThemeOverrideTest: XCTestCase {
  func testBothThemeScenariosOverrideAndTheShippedBrandingDoesNot() {
    XCTAssertNil(UseSmileIDSampleThemeScenario.brandDefault.override)
    let partner = UseSmileIDSampleThemeScenario.partnerOverride.override
    let clashing = UseSmileIDSampleThemeScenario.clashingHost.override
    XCTAssertNotNil(partner)
    XCTAssertNotNil(clashing)
    // Far from the defaults on every axis, or the scenario hides the collision it exists to show.
    XCTAssertNotEqual(partner, clashing)
    XCTAssertGreaterThan(clashing?.buttonShape ?? 0, partner?.buttonShape ?? 0)
    XCTAssertNotNil(clashing?.fontFamily)
    XCTAssertNotNil(UIFont(name: clashing?.fontFamily ?? "", size: 12), "the clashing face does not resolve")
  }

  /// The override is stated in the SDK's own types, which is what makes an SDK rename a build failure here.
  func testTheOverrideIsStatedInTheSdkColourType() {
    let partner = UseSmileIDSampleThemeScenario.partnerOverride.override
    XCTAssertEqual(partner?.primaryColor.light, partner?.primaryColor.dark)
    XCTAssertNotEqual(partner?.primaryColor, partner?.secondaryColor)
  }
}
