import Foundation
import SampleUI

/// What a deep link resolves to: a route, or a sheet layered over the route that owns it.
enum UseSmileIDSampleLink: Equatable {
  case route(Route)
  case sheet(Sheet, owner: Route)
}

/// Parses an incoming URL against the shared route table. Cold start is the case that matters: the
/// link arrives before any tab has been built, so this answers with data rather than with navigation.
enum UseSmileIDSampleLinks {
  static func resolve(_ url: URL) -> UseSmileIDSampleLink? {
    guard url.scheme == UseSmileIDSampleDeepLinks.scheme else { return nil }
    let canonical = canonicalUri(url)
    if let link = UseSmileIDSampleSheetLinks.resolve(canonical) {
      guard let owner = route(uri: link.ownerUri, query: [:]) else { return nil }
      return .sheet(link.sheet, owner: owner)
    }
    return route(uri: canonical, query: query(url)).map { .route($0) }
  }

  /// Scheme plus path, with the query dropped — the form `UseSmileIDSampleSheetLinks` matches on.
  private static func canonicalUri(_ url: URL) -> String {
    let segments = self.segments(url)
    return UseSmileIDSampleDeepLinks.scheme + "://" + segments.joined(separator: "/")
  }

  private static func segments(_ url: URL) -> [String] {
    let host = url.host.map { [$0] } ?? []
    return host + url.path.split(separator: "/").map(String.init)
  }

  private static func query(_ url: URL) -> [String: String] {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    return Dictionary(items.compactMap { item in item.value.map { (item.name, $0) } }) { _, last in last }
  }

  private static func route(uri: String, query: [String: String]) -> Route? {
    let path = uri.replacingOccurrences(of: UseSmileIDSampleDeepLinks.scheme + "://", with: "")
    let segments = path.split(separator: "/").map(String.init)
    switch segments {
    case ["products"]: return .products
    case ["verifications"]: return .verifications
    case ["settings"]: return .settings
    case ["settings", "licenses"]: return .licenses
    case ["profiles"]: return .profiles
    case ["token", "scan"]: return .scanToken
    default: break
    }
    // Two segments: a detail route whose second segment is its argument.
    if segments.count == 2 {
      switch segments[0] {
      case "verifications": return .verificationDetails(jobId: segments[1])
      case "profiles": return .profileConfig(profileId: segments[1])
      default: return nil
      }
    }
    guard segments.count == 3, segments[0] == "flow" else { return nil }
    let productId = segments[1]
    switch segments[2] {
    case "details": return .consentDetailsForm(productId: productId)
    case "id-details": return .idDetailsForm(productId: productId)
    case "run":
      return .sdkFlow(productId: productId, presentation: UseSmileIDSampleFlowRoute(id: query["route"]))
    default: return nil
    }
  }
}
