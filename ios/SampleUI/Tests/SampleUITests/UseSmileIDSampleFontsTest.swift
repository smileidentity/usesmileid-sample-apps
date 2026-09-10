@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleFontsTest: XCTestCase {
  func testEveryRampWeightRegistersItsOwnFace() {
    XCTAssertTrue(UseSmileIDSampleFonts.register())
    for (weight, name) in UseSmileIDSampleFonts.faces {
      XCTAssertNotNil(UIFont(name: name, size: 12), "weight \(weight) has no registered face")
    }
  }

  func testTheFamilyNameCannotSelectAWeight() throws {
    // Why the ramp resolves PostScript names: three faces are their own family, so "DM Sans" semibold returns regular.
    let semibold = try XCTUnwrap(UIFont(name: "DMSans-SemiBold", size: 12))
    let regular = try XCTUnwrap(UIFont(name: "DM Sans", size: 12))
    XCTAssertNotEqual(semibold.fontName, regular.fontName)
    XCTAssertEqual(regular.fontName, try XCTUnwrap(UIFont(name: "DMSans-Regular", size: 12)).fontName)
  }

  func testAnUnlistedWeightFallsBackToTheNearestFace() {
    XCTAssertEqual(UseSmileIDSampleFonts.face(weight: 450), "DMSans-Regular")
    XCTAssertEqual(UseSmileIDSampleFonts.face(weight: 650), "DMSans-SemiBold")
    XCTAssertEqual(UseSmileIDSampleFonts.face(weight: 900), "DMSans-ExtraBold")
  }

  func testEveryRampStyleResolvesToABundledFace() {
    let type = UseSmileIDSampleTheme.type
    for style in [type.textStyleDisplayLg, type.textStyleBody, type.textStyleOverline, type.buttonFont] {
      XCTAssertNotNil(UIFont(name: UseSmileIDSampleFonts.face(weight: style.weight), size: style.size))
    }
  }
}
