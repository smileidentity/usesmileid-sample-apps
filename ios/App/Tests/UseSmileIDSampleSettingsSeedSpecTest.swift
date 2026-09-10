import Foundation
import SampleUI
import XCTest

/// The UI suite seeds the switches by name, so a row added or a default changed must fail here rather than leaving a launch half-seeded.
final class UseSmileIDSampleSettingsSeedSpecTest: XCTestCase {
  func testTheSeedNamesEverySwitchAtItsShippedDefault() throws {
    let seeded = try Self.seed()
    let shipped = UseSmileIDSampleSettings()
    XCTAssertEqual(
      seeded,
      Dictionary(
        uniqueKeysWithValues: UseSmileIDSampleSetting.allCases.map { ($0.storageKey, String(shipped[$0])) }
      ),
      "ios/App/UITests/UseSmileIDSampleSettingsSeed.swift has drifted from the settings it seeds"
    )
  }

  func testEverySuiteThatLaunchesTheAppPassesTheSeed() throws {
    let directory = Self.uiTests
    let classes = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
      .filter { $0.pathExtension == "swift" }
    var launching: [String] = []
    for file in classes {
      let body = try String(contentsOf: file, encoding: .utf8)
      guard body.contains("launchArguments") else { continue }
      launching.append(file.lastPathComponent)
      XCTAssertTrue(
        body.contains("useSmileIDSampleSettingsSeed"),
        "\(file.lastPathComponent) launches the app without seeding the switches, so it inherits them"
      )
    }
    XCTAssertFalse(launching.isEmpty, "found no UI suite that launches the app")
  }

  private static func seed() throws -> [String: String] {
    let body = try String(
      contentsOf: uiTests.appendingPathComponent("UseSmileIDSampleSettingsSeed.swift"),
      encoding: .utf8
    )
    let pattern = #""-(\w+)",\s*"(\w+)""#
    let expression = try NSRegularExpression(pattern: pattern)
    let range = NSRange(body.startIndex..<body.endIndex, in: body)
    let pairs = expression.matches(in: body, range: range).compactMap { match -> (String, String)? in
      guard let key = Range(match.range(at: 1), in: body), let value = Range(match.range(at: 2), in: body) else {
        return nil
      }
      return (String(body[key]), String(body[value]))
    }
    XCTAssertEqual(pairs.count, Set(pairs.map(\.0)).count, "a key is seeded twice")
    return Dictionary(uniqueKeysWithValues: pairs)
  }

  private static var uiTests: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("UITests")
  }
}
