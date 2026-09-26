@testable import SampleUI
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
