import Foundation
import SampleUI

/// Automation arguments. Names come from `spec/launch-args.json` and are identical on all four
/// platforms; only delivery differs, and iOS delivers them as `UserDefaults` launch arguments.
///
/// Read once at launch: an argument observed later would disagree with the run it configured.
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
