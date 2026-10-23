import Foundation
import SampleUI

/// A deep link as the graph reads it: the `path` it opens and, for the run, the `route` it asked for.
struct UseSmileIDSampleLink: Equatable {
  let path: String
  let route: UseSmileIDSampleFlowRoute?
}

/// The app's URIs: paths are shared across the four apps and are `spec/njia-graph.json`'s links; the scheme is per app.
enum UseSmileIDSampleDeepLinks {
  /// The build's scheme, from the plist: a source build injects its own.
  static let scheme: String = {
    let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
    guard let scheme = (types?.first?["CFBundleURLSchemes"] as? [String])?.first else {
      preconditionFailure("Info.plist declares no URL scheme")
    }
    return scheme
  }()

  /// The graph link `url` opens, or nil for one outside `scheme`.
  static func linkOf(_ url: URL, scheme: String = scheme) -> UseSmileIDSampleLink? {
    guard url.scheme == scheme else { return nil }
    let segments = (url.host.map { [$0] } ?? []) + url.path.split(separator: "/").map(String.init)
    guard !segments.isEmpty else { return nil }
    let path = segments.joined(separator: "/")
    guard segments.count == 3, segments[0] == "flow", segments[2] == "run" else {
      return UseSmileIDSampleLink(path: path, route: nil)
    }
    let asked = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.last { $0.name == "route" }?.value
    // One URI, two presentations: `spec/routes.json` defaults the run to full screen, which the graph names apart.
    let route = UseSmileIDSampleFlowRoute(id: asked)
    return UseSmileIDSampleLink(path: route == .fullscreen ? path + "-fullscreen" : path, route: route)
  }

  /// The product a `flow/…` link runs, as its second segment names it.
  static func productId(of link: UseSmileIDSampleLink) -> String? {
    let segments = link.path.split(separator: "/").map(String.init)
    return segments.count >= 2 && segments[0] == "flow" ? segments[1] : nil
  }
}
