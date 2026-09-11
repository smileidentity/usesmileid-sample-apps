import CryptoKit
import Foundation
import XCTest

/// The listing App Store Connect receives: every field within its limit, every panel store-legal.
final class UseSmileIDSampleAppStoreListingTest: XCTestCase {
  /// Counted rather than estimated, because App Store Connect truncates silently instead of rejecting.
  private static let limits = [
    "name.txt": 30,
    "subtitle.txt": 30,
    "keywords.txt": 100,
    "promotional-text.txt": 170,
    "description.txt": 4000,
    "whats-new.txt": 4000
  ]

  private static let panels = [
    "products", "token_session", "verifications", "verification_details", "settings"
  ]

  /// The ios-phone preset; App Store Connect rejects a 6.9" screenshot at any other size.
  private static let panelSize = (width: 1320, height: 2868)

  private static var store: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // the file
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // App
      .appendingPathComponent("store")
  }

  func testEveryFieldFitsItsLimit() throws {
    for (name, limit) in Self.limits {
      let text = try copy(name)
      XCTAssertFalse(text.isEmpty, "ios/store/\(name) is empty")
      XCTAssertLessThanOrEqual(
        text.count, limit,
        "ios/store/\(name) is \(text.count) characters, over the App Store's \(limit)"
      )
    }
  }

  /// v11 generated release notes from `git log` and shipped PR numbers to partners; this is where that stops.
  func testTheCopyCarriesNoDevelopmentShorthand() throws {
    for name in Self.limits.keys {
      let text = try copy(name)
      XCTAssertNil(
        text.range(of: #"\(#\d+\)|\[\d{4}-\d{2}-\d{2}\]"#, options: .regularExpression),
        "ios/store/\(name) carries a PR number or a commit date"
      )
      XCTAssertNil(
        text.range(of: #"[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]"#, options: .regularExpression),
        "ios/store/\(name) carries an emoji"
      )
    }
  }

  func testTheDescriptionNamesTheProductTheAppDoes() throws {
    let description = try copy("description.txt")
    XCTAssertTrue(
      description.contains("SmartSelfie™ Enrollment"),
      "the listing and the app's own product list must name the first product the same way"
    )
    XCTAssertFalse(
      description.contains("SmartSelfie™ Registration"),
      "docs-v3's name for the first product; the listing takes the app's, by owner ruling"
    )
  }

  func testEveryPanelIsStoreLegal() throws {
    for panel in Self.panels {
      let url = Self.store.appendingPathComponent("screenshots/\(panel).png")
      let header = try XCTUnwrap(
        FileHandle(forReadingAtPath: url.path)?.readData(ofLength: 26),
        "ios/store/screenshots/\(panel).png is missing — run ios/store/render-store-art.sh"
      )
      let size = Self.pngSize(header)
      XCTAssertEqual(
        [size.width, size.height], [Self.panelSize.width, Self.panelSize.height],
        "\(panel).png is \(size.width)x\(size.height), not the ios-phone preset"
      )
      // 4 and 6 carry alpha, which App Store Connect rejects; storeshots flattens it on output.
      XCTAssertFalse([4, 6].contains(Int(header[25])), "\(panel).png carries an alpha channel")
    }
  }

  /// The strip is a review aid and validates as nothing, so a listing built from this directory would break.
  func testTheScreenshotDirectoryHoldsOnlyPanels() throws {
    let directory = Self.store.appendingPathComponent("screenshots")
    let found = try FileManager.default.contentsOfDirectory(atPath: directory.path)
      .filter { !$0.hasPrefix(".") }
    XCTAssertEqual(
      Set(found), Set(Self.panels.map { "\($0).png" }),
      "ios/store/screenshots must hold the panels and nothing else"
    )
  }

  /// The panels are rendered from the frames, so a frame that moved without a re-render is stale art.
  func testThePanelsWereRenderedFromTheCommittedFrames() throws {
    let lock = try String(contentsOf: Self.store.appendingPathComponent("panels.lock"), encoding: .utf8)
    let recorded = lock.split(separator: "\n").reduce(into: [String: String]()) { map, line in
      let parts = line.split(separator: " ").filter { !$0.isEmpty }
      if parts.count == 2 {
        map[String(parts[1])] = String(parts[0])
      }
    }
    XCTAssertFalse(recorded.isEmpty, "ios/store/panels.lock is empty — run ios/store/render-store-art.sh")

    for (name, hash) in recorded {
      let frame = Self.store.appendingPathComponent("frames/\(name)")
      let digest = try SHA256.hash(data: Data(contentsOf: frame))
      XCTAssertEqual(
        digest.map { String(format: "%02x", $0) }.joined(), hash,
        "\(name) has changed since the panels were rendered — run ios/store/render-store-art.sh"
      )
    }
  }

  private func copy(_ name: String) throws -> String {
    try String(contentsOf: Self.store.appendingPathComponent(name), encoding: .utf8)
      .trimmingCharacters(in: .newlines)
  }

  /// IHDR, which is fixed at bytes 16..24, so a panel's size is readable without decoding it.
  private static func pngSize(_ header: Data) -> (width: Int, height: Int) {
    func int(_ start: Int) -> Int {
      header[start..<start + 4].reduce(0) { $0 << 8 | Int($1) }
    }
    return (int(16), int(20))
  }
}
