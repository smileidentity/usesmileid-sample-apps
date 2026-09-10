import Foundation
import SampleUI

/// How long the host holds the camera before handing off, so the SDK meets a contended device.
enum UseSmileIDSampleHoldCamera: Equatable {
  case keep
  case millis(Int)

  /// Rendered in the argument's own vocabulary, so a report cannot drift from what the parser accepts.
  var description: String {
    switch self {
    case .keep: "holdCamera=\(UseSmileIDSampleLaunchArguments.holdCameraKeep)"
    case .millis(let value): "holdCamera=\(value)ms"
    }
  }
}

/// The `spec/launch-args.json` arguments, read once from `UserDefaults.standard`'s argument domain; `init()` is the spec's defaults and reads nothing.
struct UseSmileIDSampleLaunchArguments: Equatable {
  var scenario: UseSmileIDSampleScenario = .normal
  var theme: UseSmileIDSampleThemeScenario = .brandDefault
  var route: UseSmileIDSampleFlowRoute = .fullscreen
  var autostart: UseSmileIDSampleProduct?
  /// Automation precondition only — see `spec/launch-args.json`.
  var seedJobs = false
  /// The design's three profiles instead of the one empty starter; in memory, so per launch.
  var seedProfiles = false
  /// Reveals the result card on a release build. Always on in debug, so only a release run needs it.
  var probes = false
  var appLocale: String?
  var holdCamera: UseSmileIDSampleHoldCamera?
  /// Seconds a transient notice stays — see `spec/launch-args.json`. Automation only.
  var noticeWindow: Int?

  static let scenarioName = "scenario"
  static let themeName = "theme"
  static let routeName = "route"
  static let autostartName = "autostart"
  static let seedJobsName = "seedJobs"
  static let seedProfilesName = "seedProfiles"
  static let probesName = "probes"
  static let appLocaleName = "appLocale"
  static let holdCameraName = "holdCamera"
  static let noticeWindowName = "noticeWindow"

  static let names = [
    scenarioName, themeName, routeName, autostartName, seedJobsName, seedProfilesName, probesName, appLocaleName,
    holdCameraName, noticeWindowName
  ]

  static let holdCameraKeep = "keep"

  init() {}

  /// Every name is read whether this build acts on it or not, and only from the argument domain, so nothing persisted can seed a run.
  init(reading defaults: UserDefaults) {
    let arguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    self.init(raw: Dictionary(uniqueKeysWithValues: Self.names.map { ($0, arguments[$0]) }))
  }

  /// An unrecognised value falls back to its default, which is safe only because the card reports it.
  init(raw: [String: Any?]) {
    let defaults = UseSmileIDSampleLaunchArguments()
    scenario = Self.string(raw, Self.scenarioName).flatMap { UseSmileIDSampleScenario(rawValue: $0) } ?? defaults.scenario
    theme = Self.string(raw, Self.themeName).flatMap { UseSmileIDSampleThemeScenario(rawValue: $0) } ?? defaults.theme
    route = Self.string(raw, Self.routeName).flatMap { UseSmileIDSampleFlowRoute(rawValue: $0) } ?? defaults.route
    autostart = Self.string(raw, Self.autostartName).flatMap { UseSmileIDSampleProduct(rawValue: $0) }
    seedJobs = Self.bool(raw, Self.seedJobsName) ?? defaults.seedJobs
    seedProfiles = Self.bool(raw, Self.seedProfilesName) ?? defaults.seedProfiles
    probes = Self.bool(raw, Self.probesName) ?? defaults.probes
    appLocale = Self.string(raw, Self.appLocaleName)
    holdCamera = Self.holdCamera(raw)
    noticeWindow = Self.noticeWindow(raw)
  }

  /// The tag as a locale the environment can carry, or nil when it names no known language.
  var locale: Locale? {
    guard let appLocale else { return nil }
    let locale = Locale(identifier: appLocale)
    guard let code = locale.languageCode, Locale.isoLanguageCodes.contains(code) else { return nil }
    return locale
  }

  private static func string(_ raw: [String: Any?], _ name: String) -> String? {
    guard let value = raw[name] ?? nil else { return nil }
    let text = (value as? String ?? String(describing: value)).trimmingCharacters(in: .whitespaces)
    return text.isEmpty ? nil : text
  }

  /// A launch argument arrives as text; a stored default may be a number. Both read, strictly.
  private static func bool(_ raw: [String: Any?], _ name: String) -> Bool? {
    guard let value = raw[name] ?? nil else { return nil }
    if let flag = value as? Bool {
      return flag
    }
    switch String(describing: value).trimmingCharacters(in: .whitespaces).lowercased() {
    case "true": return true
    case "false": return false
    default: return nil
    }
  }

  /// Positive seconds; anything else falls back to the product's own window.
  private static func noticeWindow(_ raw: [String: Any?]) -> Int? {
    guard let seconds = string(raw, noticeWindowName).flatMap(Int.init), seconds > 0 else { return nil }
    return seconds
  }

  private static func holdCamera(_ raw: [String: Any?]) -> UseSmileIDSampleHoldCamera? {
    guard let value = string(raw, holdCameraName) else { return nil }
    if value.lowercased() == holdCameraKeep {
      return .keep
    }
    guard let millis = Int(value), millis > 0 else { return nil }
    return .millis(millis)
  }
}
