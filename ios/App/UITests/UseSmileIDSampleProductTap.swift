import XCTest

extension XCUIApplication {
  /// Taps a product card and, when the scanner answers because no session is live, links a simulated one: every run needs a token.
  func useSmileIDSampleStartProduct(_ productId: String) {
    let card = descendants(matching: .any).matching(identifier: "sample_product_card_\(productId)").firstMatch
    XCTAssertTrue(card.waitForExistence(timeout: 10), productId)
    card.tap()
    let simulate = descendants(matching: .any).matching(identifier: "sample_token_simulate").firstMatch
    if simulate.waitForExistence(timeout: 3) {
      simulate.tap()
    }
  }
}
