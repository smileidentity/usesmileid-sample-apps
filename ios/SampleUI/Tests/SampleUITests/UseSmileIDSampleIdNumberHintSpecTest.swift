import Foundation
@testable import SampleUI
import XCTest

/// spec/id-number-hints.json: the hint, that it fits its own regex, and that NSRegularExpression compiles every case.
final class UseSmileIDSampleIdNumberHintSpecTest: XCTestCase {
  private func cases() throws -> [(regex: String, hint: String?)] {
    let items = try XCTUnwrap(try UseSmileIDSampleSpecFiles.object("id-number-hints.json")["cases"] as? [[String: Any]])
    return items.map { ($0["regex"] as? String ?? "", $0["hint"] as? String) }
  }

  func testTheFileHasCasesInsideAndOutsideTheSubset() throws {
    let all = try cases()
    XCTAssertGreaterThan(all.filter { $0.hint != nil }.count, 20)
    XCTAssertTrue(all.contains { $0.hint == nil })
  }

  func testEveryHintMatchesTheSpec() throws {
    for item in try cases() {
      XCTAssertEqual(UseSmileIDSampleIdNumberHint.example(item.regex), item.hint, item.regex)
    }
  }

  func testEveryExampleMatchesItsOwnRegex() throws {
    for item in try cases() {
      guard let hint = item.hint else { continue }
      XCTAssertTrue(UseSmileIDSampleIdNumberHint.accepts(item.regex, hint), "\(hint) against \(item.regex)")
    }
  }

  func testEveryRegexCompilesHere() throws {
    for item in try cases() {
      XCTAssertNotNil(UseSmileIDSampleIdNumberHint.compiled(item.regex), item.regex)
    }
  }

  func testTheNumberIsTrimmedAndMustMatchTheWholeRegex() {
    XCTAssertTrue(UseSmileIDSampleIdNumberHint.accepts("^[0-9]{1,9}$", " 12345678 "))
    XCTAssertFalse(UseSmileIDSampleIdNumberHint.accepts("^[0-9]{1,9}$", "AO12345678"))
    XCTAssertFalse(UseSmileIDSampleIdNumberHint.accepts("[0-9]{3}", "12345"))
    XCTAssertFalse(UseSmileIDSampleIdNumberHint.accepts("^[0-9]{1,9}$", ""))
  }

  func testARegexThisEngineCannotCompileChecksNothing() {
    let type = UseSmileIDSampleKycIdType(id: "X", type: "X", label: "Tax number", regex: "^[0-9")
    XCTAssertTrue(UseSmileIDSampleIdNumberHint.accepts(type.regex, "anything"))
    XCTAssertEqual(UseSmileIDSampleIdNumberHint.placeholder(type), "Enter your Tax number")
    XCTAssertNil(UseSmileIDSampleIdNumberHint.error(type, "anything"))
  }

  func testATypeWithNoRegexChecksNothingRatherThanLockingContinue() {
    XCTAssertTrue(UseSmileIDSampleIdNumberHint.accepts("", "12345"))
    let type = UseSmileIDSampleKycIdType(id: "X", type: "X", label: "Tax number", regex: "")
    XCTAssertEqual(UseSmileIDSampleIdNumberHint.placeholder(type), "Enter your Tax number")
    XCTAssertNil(UseSmileIDSampleIdNumberHint.error(type, "12345"))
  }

  func testTheFieldWaitsForATypeThenShowsTheExample() {
    XCTAssertEqual(UseSmileIDSampleIdNumberHint.placeholder(nil), "Choose an ID type first")
    let type = UseSmileIDSampleKycIdType(id: "NIN", type: "NIN", label: "National ID", regex: "^[0-9]{11}$")
    XCTAssertEqual(UseSmileIDSampleIdNumberHint.placeholder(type), "e.g. 00000000000")
    XCTAssertEqual(UseSmileIDSampleIdNumberHint.error(type, "123"), "Doesn't match the National ID format, e.g. 00000000000")
  }
}
