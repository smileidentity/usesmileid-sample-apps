import Njia
import SampleUI
@testable import UseSmileIDSample
import XCTest

final class UseSmileIDSampleRoutesSpecTest: XCTestCase {
  private var specRoutes: [SpecRoute] = []

  override func setUpWithError() throws {
    let routes = try XCTUnwrap(UseSmileIDSampleSpec.object("routes.json")["routes"] as? [[String: Any]])
    specRoutes = try routes.map { try SpecRoute($0) }
    // Guarded in setUp, not in one test, so no consumer can pass vacuously on a parse miss.
    XCTAssertFalse(specRoutes.isEmpty, "extracted no routes from spec/routes.json")
  }

  func testEverySpecRouteIsTheGraphStepTheIosColumnNamesLinkedAtItsPath() throws {
    let graph = try UseSmileIDSampleNjiaSpec.graph()
    for route in specRoutes {
      let step = try XCTUnwrap(graph.steps.first { $0.id == route.id }, "\(route.id): no step in the graph")
      XCTAssertEqual(step.link, String(route.path.dropFirst()), "\(route.id): link")
      XCTAssertEqual(route.ios.components(separatedBy: " | ").first, "UseSmileIDSampleStep.\(step.kind.rawValue)", "\(route.id): iOS binding")
    }
  }

  func testEveryStepIdIsItsKindsWireName() throws {
    for step in try UseSmileIDSampleNjiaSpec.graph().steps {
      XCTAssertEqual(step.id, step.kind.rawValue)
    }
  }

  func testASpecSheetIsASheetStepAndNothingElseIs() throws {
    let graph = try UseSmileIDSampleNjiaSpec.graph()
    for route in specRoutes {
      let step = try XCTUnwrap(graph.steps.first { $0.id == route.id })
      XCTAssertEqual(step.presentation == .sheet, route.isSheet, "\(route.id): sheet")
    }
  }

  /// Every link opens at its own step, with the stack a user would have had, once its product's facts are set.
  func testEverySpecLinkOpensAtItsStep() throws {
    let graph = try UseSmileIDSampleNjiaSpec.graph()
    for route in specRoutes {
      let link = try XCTUnwrap(UseSmileIDSampleDeepLinks.linkOf(XCTUnwrap(URL(string: route.exampleUri))), "\(route.id): no link")
      // A product whose run reaches the step: only Authentication asks for a user ID.
      let product: UseSmileIDSampleProduct = route.id == "authUserId" ? .smartSelfieAuth : .biometricKyc
      let facts = UseSmileIDSampleDeepLinks.productId(of: link) == nil
        ? []
        : useSmileIDSampleFacts(product, bindsIdDetails: false, route: link.route ?? .shell)
      let engine = try XCTUnwrap(try NjiaKit.openLink(graph, link: link.path, facts: facts), "\(route.id): \(link.path) refused")
      let top = try XCTUnwrap(engine.top)
      let expected = route.id == "sdkFlow" && link.route == .fullscreen ? "sdkFlowFullScreen" : route.id
      XCTAssertEqual(top.step, expected, "\(route.id): opened at")
    }
  }

  func testAnUnknownLinkOpensNothing() throws {
    let graph = try UseSmileIDSampleNjiaSpec.graph()
    let nope = try XCTUnwrap(UseSmileIDSampleDeepLinks.linkOf(XCTUnwrap(URL(string: "\(UseSmileIDSampleDeepLinks.scheme)://nope"))))
    XCTAssertNil(try NjiaKit.openLink(graph, link: nope.path))
    XCTAssertNil(try UseSmileIDSampleDeepLinks.linkOf(XCTUnwrap(URL(string: "usesmileid-sample-android://products"))))
  }

  func testTheFlowRouteEnumMatchesTheSpecValuesAndDefault() throws {
    let flow = try XCTUnwrap(specRoutes.first { $0.id == "sdkFlow" })
    let arg = try XCTUnwrap(flow.args.first { $0.name == "route" })
    let values = try XCTUnwrap(
      arg.type.firstMatch(of: #"enum\(([^)]*)\)"#),
      "sdkFlow.route type is not enum(...): \(arg.type)"
    ).split(separator: ",").map(String.init)
    XCTAssertEqual(values, UseSmileIDSampleFlowRoute.allCases.map(\.id))
    XCTAssertEqual(arg.defaultValue, UseSmileIDSampleFlowRoute.fullscreen.id, "spec default")
    XCTAssertEqual(UseSmileIDSampleFlowRoute(id: "nonsense"), .fullscreen)
    XCTAssertEqual(UseSmileIDSampleFlowRoute(id: nil), .fullscreen)
  }

  func testTheFlowRouteQueryArgumentPicksTheRunStep() throws {
    let shell = try XCTUnwrap(URL(string: "\(UseSmileIDSampleDeepLinks.scheme)://flow/biometricKyc/run?route=shell"))
    let shellLink = try XCTUnwrap(UseSmileIDSampleDeepLinks.linkOf(shell))
    XCTAssertEqual(shellLink, UseSmileIDSampleLink(path: "flow/biometricKyc/run", route: .shell))
    XCTAssertEqual(UseSmileIDSampleDeepLinks.productId(of: shellLink), "biometricKyc")
    let plain = try XCTUnwrap(URL(string: "\(UseSmileIDSampleDeepLinks.scheme)://flow/biometricKyc/run"))
    XCTAssertEqual(UseSmileIDSampleDeepLinks.linkOf(plain), UseSmileIDSampleLink(path: "flow/biometricKyc/run-fullscreen", route: .fullscreen))
  }

  func testTheSchemeIsTheIosEntryInAppIdentity() throws {
    let sourceMode = Bundle.main.object(forInfoDictionaryKey: "UseSmileIDSampleSourceMode") as? String == "YES"
    let ios = try iosIdentity(sourceMode ? "sourceMode" : "apps")
    XCTAssertEqual(UseSmileIDSampleDeepLinks.scheme, ios["urlScheme"] as? String)
  }

  /// A source build installs beside the store app, so it claims none of the registry schemes.
  func testSourceModeSchemesAreDistinctFromEveryRegistryScheme() throws {
    let identity = try UseSmileIDSampleSpec.object("app-identity.json")
    let registry = try Set(XCTUnwrap(identity["apps"] as? [[String: Any]]).compactMap { $0["urlScheme"] as? String })
    let source = try XCTUnwrap(identity["sourceMode"] as? [[String: Any]]).compactMap { $0["urlScheme"] as? String }
    XCTAssertFalse(source.isEmpty)
    for scheme in source {
      XCTAssertFalse(registry.contains(scheme), "\(scheme) is also a registry scheme")
    }
  }

  func testTheShellManifestClaimsTheSameSchemeAndBundleId() throws {
    let manifest = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("project.yml")
    let yaml = try String(contentsOf: manifest, encoding: .utf8)
    let ios = try iosIdentity("apps")
    let bundleId = try XCTUnwrap(ios["bundleIdentifier"] as? String)
    XCTAssertTrue(
      yaml.contains("PRODUCT_BUNDLE_IDENTIFIER: \(bundleId)"),
      "project.yml does not declare \(bundleId)"
    )
    let scheme = try XCTUnwrap(ios["urlScheme"] as? String)
    let displayName = try XCTUnwrap(ios["displayName"] as? String)
    for line in [
      "USESMILEID_SAMPLE_URL_SCHEME: \(scheme)",
      "USESMILEID_SAMPLE_DISPLAY_NAME: \(displayName)",
      "CFBundleURLSchemes: [$(USESMILEID_SAMPLE_URL_SCHEME)]",
      "CFBundleDisplayName: $(USESMILEID_SAMPLE_DISPLAY_NAME)"
    ] {
      XCTAssertTrue(yaml.contains(line), "project.yml does not declare \(line)")
    }
  }

  private func iosIdentity(_ block: String) throws -> [String: Any] {
    let identity = try UseSmileIDSampleSpec.object("app-identity.json")
    let entries = try XCTUnwrap(identity[block] as? [[String: Any]], "no \(block) in spec/app-identity.json")
    return try XCTUnwrap(entries.first { $0["platform"] as? String == "ios" }, "no ios entry under \(block)")
  }
}

private struct SpecRoute {
  let id: String
  let path: String
  let presentation: String
  let ios: String
  let args: [SpecArg]

  var isSheet: Bool {
    presentation.hasSuffix("Sheet")
  }

  var exampleUri: String {
    let filled = path.replacing(#":([A-Za-z][A-Za-z0-9]*)"#) { "sample-\($0)" }
    return UseSmileIDSampleDeepLinks.scheme + "://" + filled.dropFirst()
  }

  init(_ json: [String: Any]) throws {
    id = try XCTUnwrap(json["id"] as? String)
    path = try XCTUnwrap(json["path"] as? String)
    presentation = try XCTUnwrap(json["presentation"] as? String)
    let platform = try XCTUnwrap(json["platform"] as? [String: Any])
    ios = try XCTUnwrap(platform["ios"] as? String)
    args = (json["args"] as? [[String: Any]] ?? []).map(SpecArg.init)
  }
}

private struct SpecArg {
  let name: String
  let type: String
  let required: Bool
  let defaultValue: String?

  init(_ json: [String: Any]) {
    name = json["name"] as? String ?? ""
    type = json["type"] as? String ?? ""
    required = json["required"] as? Bool ?? false
    defaultValue = json["default"] as? String
  }
}

private extension String {
  func firstMatch(of pattern: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
          let range = Range(match.range(at: 1), in: self)
    else { return nil }
    return String(self[range])
  }

  func replacing(_ pattern: String, with transform: (String) -> String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
    var result = self
    let matches = regex.matches(in: self, range: NSRange(startIndex..., in: self)).reversed()
    for match in matches {
      guard let whole = Range(match.range, in: result),
            let group = Range(match.range(at: 1), in: result) else { continue }
      result.replaceSubrange(whole, with: transform(String(result[group])))
    }
    return result
  }
}
