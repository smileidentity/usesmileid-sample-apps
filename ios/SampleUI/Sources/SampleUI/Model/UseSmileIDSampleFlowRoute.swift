/// The SDK flow's two presentations — one route, two containers (`spec/routes.json` → `sdkFlow`).
public enum UseSmileIDSampleFlowRoute: String, CaseIterable, Codable, Sendable {
  case fullscreen
  case shell

  public var id: String {
    rawValue
  }

  /// Restored identifiers fall back rather than throw, so a rename cannot crash a restore.
  public init(id: String?) {
    self = UseSmileIDSampleFlowRoute(rawValue: id?.lowercased() ?? "") ?? .fullscreen
  }
}
