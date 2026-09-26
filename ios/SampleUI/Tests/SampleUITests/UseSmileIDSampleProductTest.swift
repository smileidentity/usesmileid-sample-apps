@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleProductTest: XCTestCase {
  func testEveryProductResolvesAHue() {
    // A missing hue falls back to a grey tile indistinguishable from a real one, so it fails here instead.
    for product in UseSmileIDSampleProduct.allCases {
      XCTAssertNotNil(product.hue, "\(product.id) has no entry in productHues")
    }
  }

  func testTheProductIdsMatchTheSpec() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("spec/design-tokens.json")
    let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    let deltas = json?["deltas"] as? [[String: Any]] ?? []
    let hues = deltas.first { $0["id"] as? String == "productHues" }?["hues"] as? [String: Any]
    XCTAssertEqual(
      Set(UseSmileIDSampleProduct.allCases.map(\.id)),
      Set(hues?.keys ?? [:].keys),
      "the product list and spec/design-tokens.json productHues disagree"
    )
  }
}

final class UseSmileIDSampleColorMathTest: XCTestCase {
  func testInkCrossesOverOnRelativeLuminance() {
    // The first reads light as perceptual grey and dark as WCAG luminance, so grey would pick the wrong ink.
    XCTAssertEqual(Color(red: 0x3a / 255, green: 0x49 / 255, blue: 0xb4 / 255).inkOn, SmileColorLight.colorTextInverse)
    XCTAssertEqual(Color(red: 0x2c / 255, green: 0xc0 / 255, blue: 0x5c / 255).inkOn, smileOffBlackLight)
  }

  func testLuminanceMatchesTheWcagFormula() {
    XCTAssertEqual(Color(red: 1, green: 1, blue: 1).luminance, 1, accuracy: 0.001)
    XCTAssertEqual(Color(red: 0x15 / 255, green: 0x1f / 255, blue: 0x72 / 255).luminance, 0.024, accuracy: 0.001)
  }
}
