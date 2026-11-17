import Foundation
@testable import SampleUI
import XCTest

/// spec/error-handling.json: the message and the one action every failure resolves to.
final class UseSmileIDSampleErrorHandlingSpecTest: XCTestCase {
  /// A resolution as the spec states one: keys and ids, with the action's limit where the row has none.
  private struct Expected: Equatable {
    let id: String
    let message: String
    let action: String
    let backoffSeconds: [Int]
    let maxUses: Int?
    let waitsFor: String?
  }

  private var file: [String: Any] = [:]
  private var strings: [String: Any] = [:]

  override func setUpWithError() throws {
    file = try UseSmileIDSampleSpecFiles.object("error-handling.json")
    strings = try UseSmileIDSampleSpecFiles.object("l10n/app/en.json")
  }

  private func rows(_ section: String) throws -> [[String: Any]] {
    try XCTUnwrap(file[section] as? [[String: Any]])
  }

  private func actions() throws -> [String: [String: Any]] {
    try XCTUnwrap(file["actions"] as? [String: [String: Any]])
  }

  private func expected(_ row: [String: Any]) throws -> Expected {
    let action = row["action"] as? String ?? ""
    let actionLimit = try actions()[action]?["maxUses"] as? Int
    return Expected(
      id: row["id"] as? String ?? "",
      message: row["message"] as? String ?? "",
      action: action,
      backoffSeconds: row["backoffSeconds"] as? [Int] ?? [],
      maxUses: row["maxUses"] as? Int ?? actionLimit,
      waitsFor: row["waitsFor"] as? String
    )
  }

  private func stated(_ resolution: UseSmileIDSampleErrorResolution) -> Expected {
    Expected(
      id: resolution.id,
      message: resolution.message.rawValue,
      action: resolution.action.rawValue,
      backoffSeconds: resolution.backoffSeconds,
      maxUses: resolution.maxUses,
      waitsFor: resolution.waitsForConnection ? "connection" : nil
    )
  }

  private func row(_ id: String) throws -> Expected {
    try expected(XCTUnwrap((rows("submission") + rows("result")).first { $0["id"] as? String == id }))
  }

  func testTheTableHoldsTheSpecsRowsInOrder() throws {
    XCTAssertEqual(UseSmileIDSampleErrorHandling.submission.map(\.id), try rows("submission").map { $0["id"] as? String ?? "" })
    XCTAssertEqual(UseSmileIDSampleErrorHandling.result.map(\.id), try rows("result").map { $0["id"] as? String ?? "" })
  }

  func testEveryRowResolvesToItsMessageActionAndLimits() throws {
    for row in try rows("submission") {
      let text = (row["serverMessageContains"] as? [String])?.first
      for status in row["status"] as? [Int] ?? [] {
        XCTAssertEqual(stated(UseSmileIDSampleErrorHandling.forStatus(status, serverMessage: text)), try expected(row), "\(status)")
      }
      if let transport = (row["transport"] as? String).flatMap(UseSmileIDSampleTransportFailure.init(rawValue:)) {
        XCTAssertEqual(stated(UseSmileIDSampleErrorHandling.forTransport(transport)), try expected(row), "\(transport)")
      }
    }
    for row in try rows("result") {
      let text = (row["serverMessageContains"] as? [String])?.first
      for reason in row["reasons"] as? [String] ?? [] {
        XCTAssertEqual(stated(UseSmileIDSampleErrorHandling.forReason(reason, serverMessage: text)), try expected(row), reason)
      }
    }
  }

  func testEveryCaseResolvesAsTheSpecSays() throws {
    let cases = try rows("cases")
    XCTAssertFalse(cases.isEmpty)
    for item in cases {
      let text = item["serverMessage"] as? String
      let resolved: UseSmileIDSampleErrorResolution = if let status = item["status"] as? Int {
        UseSmileIDSampleErrorHandling.forStatus(status, serverMessage: text)
      } else if let transport = (item["transport"] as? String).flatMap(UseSmileIDSampleTransportFailure.init(rawValue:)) {
        UseSmileIDSampleErrorHandling.forTransport(transport)
      } else {
        UseSmileIDSampleErrorHandling.forReason(item["reason"] as? String, serverMessage: text)
      }
      XCTAssertEqual(resolved.id, item["resolves"] as? String, "\(item)")
    }
  }

  func testAFailureTheTableDoesNotNameResolvesAsTheFallback() throws {
    let fallback = try XCTUnwrap(file["fallback"] as? [String: String])
    XCTAssertEqual(stated(UseSmileIDSampleErrorHandling.forStatus(599)), try row(fallback["submission"] ?? ""))
    XCTAssertEqual(stated(UseSmileIDSampleErrorHandling.forReason("not_in_the_table")), try row(fallback["result"] ?? ""))
    XCTAssertEqual(stated(UseSmileIDSampleErrorHandling.forReason(nil)), try row(fallback["result"] ?? ""))
  }

  func testEveryFraudAndComplianceOutcomeShowsTheOneMessage() throws {
    let notVerified = try XCTUnwrap(rows("result").first { $0["id"] as? String == "notVerified" })
    let reasons = try XCTUnwrap(notVerified["reasons"] as? [String])
    XCTAssertGreaterThan(reasons.count, 1)
    for reason in reasons {
      let resolved = UseSmileIDSampleErrorHandling.forReason(reason, serverMessage: "Verification failed: \(reason)")
      XCTAssertEqual(resolved.message, .notVerified, reason)
      XCTAssertEqual(resolved.action, .exit, reason)
    }
    XCTAssertEqual(strings[UseSmileIDSampleErrorMessage.notVerified.rawValue] as? String, "We couldn't verify your identity.")
    XCTAssertEqual(UseSmileIDSampleStrings.errorNotVerified, "We couldn't verify your identity.")
  }

  func testTheActionsAreTheSpecsWithItsButtonsAndLimits() throws {
    let actions = try actions()
    XCTAssertEqual(Set(UseSmileIDSampleErrorAction.allCases.map(\.rawValue)), Set(actions.keys))
    for action in UseSmileIDSampleErrorAction.allCases {
      XCTAssertEqual(action.buttonKey, actions[action.rawValue]?["button"] as? String, action.rawValue)
      XCTAssertEqual(action.maxUses, actions[action.rawValue]?["maxUses"] as? Int, action.rawValue)
    }
  }

  func testEveryMessageAndButtonHasAString() throws {
    let used = try Set((rows("submission") + rows("result")).map { $0["message"] as? String ?? "" })
    XCTAssertEqual(Set(UseSmileIDSampleErrorMessage.allCases.map(\.rawValue)), used)
    for key in used.union(UseSmileIDSampleErrorAction.allCases.map(\.buttonKey)) {
      XCTAssertFalse((strings[key] as? String ?? "").isEmpty, key)
    }
  }
}
