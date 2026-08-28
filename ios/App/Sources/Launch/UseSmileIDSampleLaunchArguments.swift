import Foundation
import SampleUI

/// Automation arguments named by `spec/launch-args.json`; iOS delivers them as launch arguments.
/// Read once at launch, or an argument would disagree with the run it configured.
struct UseSmileIDSampleLaunchArguments {
  let scenario: String?
  let theme: String?
  let route: UseSmileIDSampleFlowRoute?
  let probes: Bool

  init(defaults: UserDefaults = .standard) {
    scenario = defaults.string(forKey: "scenario")
    theme = defaults.string(forKey: "theme")
    route = defaults.string(forKey: "route").map { UseSmileIDSampleFlowRoute(id: $0) }
    probes = defaults.bool(forKey: "probes")
  }
}
