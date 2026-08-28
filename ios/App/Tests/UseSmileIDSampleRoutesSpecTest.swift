import SampleUI
@testable import UseSmileIDSample
import XCTest

/// Asserts the shell's routes against `spec/routes.json`, the four-platform route contract: a renamed
/// case, argument label or path otherwise kills a deep link with no compile error.
final class UseSmileIDSampleRoutesSpecTest: XCTestCase {
  private var specRoutes: [SpecRoute] = []

  override func setUpWithError() throws {
    let routes = try XCTUnwrap(UseSmileIDSampleSpec.object("routes.json")["routes"] as? [[String: Any]])
    specRoutes = try routes.map { try SpecRoute($0) }
    // Guarded in setUp, not in one test, so no consumer can pass vacuously on a parse miss.
    XCTAssertFalse(specRoutes.isEmpty, "extracted no routes from spec/routes.json")
  }

  func testEverySpecRouteBindsToTheCaseTheSpecNames() throws {
    for route in specRoutes where !route.isSheet {
      let parsed = try XCTUnwrap(
        try UseSmileIDSampleLinks.resolve(XCTUnwrap(URL(string: route.exampleUri))),
        "\(route.id): \(route.exampleUri) resolves to no route"
      )
      guard case .route(let bound) = parsed else {
        return XCTFail("\(route.id): resolved to a sheet, not a route")
      }
      XCTAssertEqual(route.ios, binding(for: bound), "\(route.id): iOS binding")
    }
  }

  /// R12: re-adding a destination for a sheet path is what left the scrim covering a grey void.
  func testEverySheetRouteResolvesToItsOwnerAndNoRouteClaimsIt() throws {
    let sheets = specRoutes.filter(\.isSheet)
    XCTAssertFalse(sheets.isEmpty, "no sheet routes extracted from spec/routes.json")
    for route in sheets {
      let parsed = try XCTUnwrap(
        try UseSmileIDSampleLinks.resolve(XCTUnwrap(URL(string: route.exampleUri))),
        "\(route.id): \(route.exampleUri) resolves to nothing"
      )
      guard case .sheet(let sheet, let owner) = parsed else {
        return XCTFail("\(route.id): a sheet path resolved to a destination, which R12 forbids")
      }
      XCTAssertEqual(route.ios, "Sheet." + sheet.rawValue, "\(route.id): iOS binding")
      XCTAssertNotNil(owner, "\(route.id): no owner")
    }
  }

  /// The other side of it: the resolver must not swallow a route the table owns, query or no query.
  func testTheSheetResolverLeavesEveryOtherRouteAlone() throws {
    for route in specRoutes where !route.isSheet {
      XCTAssertNil(
        UseSmileIDSampleSheetLinks.resolve(route.exampleUri),
        "\(route.id) is not a sheet"
      )
    }
    // A drawer link carries ?probes=true, which the launch arguments read rather than the route.
    let drawer = try XCTUnwrap(specRoutes.first { $0.id == "scenarioDrawer" })
    XCTAssertNotNil(UseSmileIDSampleSheetLinks.resolve(drawer.exampleUri + "?probes=true"))
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
    // An unreadable value falls back to the spec default rather than throwing.
    XCTAssertEqual(UseSmileIDSampleFlowRoute(id: "nonsense"), .fullscreen)
    XCTAssertEqual(UseSmileIDSampleFlowRoute(id: nil), .fullscreen)
  }

  func testTheFlowRouteQueryArgumentIsRead() throws {
    let shell = try XCTUnwrap(URL(string: "\(UseSmileIDSampleDeepLinks.scheme)://flow/biometricKyc/run?route=shell"))
    guard case .route(.sdkFlow(let productId, let presentation)) = UseSmileIDSampleLinks.resolve(shell) else {
      return XCTFail("the flow link did not resolve")
    }
    XCTAssertEqual(productId, "biometricKyc")
    XCTAssertEqual(presentation, .shell)
  }

  func testTheSchemeIsTheIosEntryInAppIdentity() throws {
    let identity = try UseSmileIDSampleSpec.object("app-identity.json")
    let apps = try XCTUnwrap(identity["apps"] as? [[String: Any]])
    let ios = try XCTUnwrap(apps.first { $0["platform"] as? String == "ios" })
    XCTAssertEqual(UseSmileIDSampleDeepLinks.scheme, ios["urlScheme"] as? String)
  }

  /// project.yml is a third copy of both, and drift there kills every deep link at the OS.
  func testTheShellManifestClaimsTheSameSchemeAndBundleId() throws {
    let manifest = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("project.yml")
    let yaml = try String(contentsOf: manifest, encoding: .utf8)
    let identity = try UseSmileIDSampleSpec.object("app-identity.json")
    let apps = try XCTUnwrap(identity["apps"] as? [[String: Any]])
    let ios = try XCTUnwrap(apps.first { $0["platform"] as? String == "ios" })
    let bundleId = try XCTUnwrap(ios["bundleIdentifier"] as? String)
    XCTAssertTrue(
      yaml.contains("PRODUCT_BUNDLE_IDENTIFIER: \(bundleId)"),
      "project.yml does not declare \(bundleId)"
    )
    XCTAssertTrue(
      yaml.contains("CFBundleURLSchemes: [\(UseSmileIDSampleDeepLinks.scheme)]"),
      "project.yml does not claim \(UseSmileIDSampleDeepLinks.scheme)"
    )
  }

  /// Renders the case the spec's `platform.ios` cell names, labels included.
  private func binding(for route: Route) -> String {
    switch route {
    case .products: "Route.products"
    case .verifications: "Route.verifications"
    case .settings: "Route.settings"
    case .licenses: "Route.licenses"
    case .verificationDetails: "Route.verificationDetails(jobId:)"
    case .consentDetailsForm: "Route.consentDetailsForm(productId:)"
    case .idDetailsForm: "Route.idDetailsForm(productId:)"
    case .sdkFlow: "Route.sdkFlow(productId:presentation:)"
    case .profiles: "Route.profiles"
    case .profileConfig: "Route.profileConfig(profileId:)"
    case .scanToken: "Route.scanToken"
    }
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

  /// The spec path with every `:param` filled in, which is what a real link looks like.
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
  /// First capture group, or nil — enough for the two patterns this test needs.
  func firstMatch(of pattern: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
          let range = Range(match.range(at: 1), in: self)
    else { return nil }
    return String(self[range])
  }

  /// Replaces every match of `pattern`'s first group using `transform`.
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
