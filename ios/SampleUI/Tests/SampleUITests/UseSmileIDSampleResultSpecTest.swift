import Foundation
@testable import SampleUI
import XCTest

/// The card's model against `spec/result-card.schema.json`, field for field.
final class UseSmileIDSampleResultSpecTest: XCTestCase {
  private var schema: [String: Any] = [:]

  override func setUpWithError() throws {
    schema = try UseSmileIDSampleSpecFiles.object("result-card.schema.json")
    XCTAssertFalse(schema.isEmpty, "read no schema")
  }

  func testTheModelCarriesExactlyTheSchemaFields() throws {
    let properties = try XCTUnwrap(schema["properties"] as? [String: Any])
    XCTAssertFalse(properties.isEmpty, "extracted no properties from the schema")
    XCTAssertEqual(Set(properties.keys), Set(Self.modelFields().keys))
  }

  func testEveryFieldTheSchemaRequiresIsPresent() throws {
    let required = try XCTUnwrap(schema["required"] as? [String])
    XCTAssertFalse(required.isEmpty, "extracted no required fields")
    XCTAssertEqual(required.filter { Self.modelFields()[$0] == nil }, [])
  }

  func testTheCallbackCountsAreIntegers() {
    let fields = Self.modelFields()
    for name in ["resultCallbackCount", "refreshCallbackCount"] {
      XCTAssertTrue(fields[name] is Int, "\(name) is not an Int")
    }
  }

  func testTheRouteValuesAreTheOnesTheSchemaEnumerates() throws {
    let properties = try XCTUnwrap(schema["properties"] as? [String: Any])
    let route = try XCTUnwrap(properties["route"] as? [String: Any])
    XCTAssertEqual(route["enum"] as? [String], UseSmileIDSampleFlowRoute.allCases.map(\.id))
  }

  /// The published package exposes no runtime accessor, and the pin in Package.swift must not stand in.
  func testTheSdkVersionStaysNilOnIos() {
    XCTAssertNil(UseSmileIDSampleFlowResult().snapshot.sdkVersion)
  }

  private static func modelFields() -> [String: Any] {
    let fields = Mirror(reflecting: UseSmileIDSampleFlowResult().snapshot).children
    return Dictionary(uniqueKeysWithValues: fields.compactMap { child in child.label.map { ($0, child.value) } })
  }
}
