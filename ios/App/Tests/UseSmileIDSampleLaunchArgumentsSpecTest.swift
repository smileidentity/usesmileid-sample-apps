import SampleUI
@testable import UseSmileIDSample
import XCTest

final class UseSmileIDSampleLaunchArgumentsSpecTest: XCTestCase {
  /// `(name, default)` in spec order; a null default reads as nil.
  private var specArgs: [(String, String?)] = []

  override func setUpWithError() throws {
    let args = try XCTUnwrap(UseSmileIDSampleSpec.object("launch-args.json")["args"] as? [[String: Any]])
    specArgs = try args.map { arg in
      let name = try XCTUnwrap(arg["name"] as? String)
      let fallback = arg["default"]
      let text: String? = switch fallback {
      case let string as String: string
      case let flag as Bool: String(flag)
      default: nil
      }
      return (name, text)
    }
    XCTAssertFalse(specArgs.isEmpty, "extracted no launch arguments")
  }

  func testTheCanonicalNamesMatchTheSpec() {
    XCTAssertEqual(specArgs.map(\.0), UseSmileIDSampleLaunchArguments.names)
  }

  func testTheDefaultsMatchTheSpec() {
    let defaults = UseSmileIDSampleLaunchArguments()
    let declared: [String: String?] = [
      UseSmileIDSampleLaunchArguments.scenarioName: defaults.scenario.id,
      UseSmileIDSampleLaunchArguments.themeName: defaults.theme.id,
      UseSmileIDSampleLaunchArguments.routeName: defaults.route.id,
      UseSmileIDSampleLaunchArguments.autostartName: defaults.autostart?.id,
      UseSmileIDSampleLaunchArguments.seedJobsName: String(defaults.seedJobs),
      UseSmileIDSampleLaunchArguments.probesName: String(defaults.probes),
      UseSmileIDSampleLaunchArguments.appLocaleName: defaults.appLocale,
      UseSmileIDSampleLaunchArguments.holdCameraName: defaults.holdCamera?.description
    ]
    XCTAssertEqual(Dictionary(uniqueKeysWithValues: specArgs), declared)
  }

  func testAnEmptyLaunchIsTheDeclaredDefaults() {
    XCTAssertEqual(UseSmileIDSampleLaunchArguments(raw: [:]), UseSmileIDSampleLaunchArguments())
  }

  func testEveryArgumentIsReadFromItsCanonicalName() {
    let args = UseSmileIDSampleLaunchArguments(raw: [
      "scenario": "expiredToken",
      "theme": "clashingHost",
      "route": "shell",
      "autostart": "biometricKyc",
      "seedJobs": "true",
      "probes": true,
      "appLocale": "fr-FR",
      "holdCamera": "keep"
    ])
    XCTAssertEqual(args.scenario, .expiredToken)
    XCTAssertEqual(args.theme, .clashingHost)
    XCTAssertEqual(args.route, .shell)
    XCTAssertEqual(args.autostart, .biometricKyc)
    XCTAssertTrue(args.seedJobs)
    XCTAssertTrue(args.probes)
    XCTAssertEqual(args.appLocale, "fr-FR")
    XCTAssertEqual(args.holdCamera, .keep)
  }

  func testTheRetiredSandboxArgumentIsNeitherDeclaredNorRead() {
    XCTAssertFalse(UseSmileIDSampleLaunchArguments.names.contains("sandbox"))
    XCTAssertEqual(UseSmileIDSampleLaunchArguments(raw: ["sandbox": false]), UseSmileIDSampleLaunchArguments())
  }

  /// A launch argument is text; a stored default can be a Bool. Both read, and only the two words count.
  func testTheBooleanArgumentsReadEitherType() {
    XCTAssertTrue(UseSmileIDSampleLaunchArguments(raw: ["seedJobs": true]).seedJobs)
    XCTAssertTrue(UseSmileIDSampleLaunchArguments(raw: ["seedJobs": "TRUE"]).seedJobs)
    XCTAssertTrue(UseSmileIDSampleLaunchArguments(raw: ["probes": "true"]).probes)
    XCTAssertTrue(UseSmileIDSampleLaunchArguments(raw: ["probes": true]).probes)
    XCTAssertFalse(UseSmileIDSampleLaunchArguments(raw: ["probes": "yes"]).probes)
  }

  func testHoldCameraAcceptsMillisecondsAsWellAsKeep() {
    XCTAssertEqual(UseSmileIDSampleLaunchArguments(raw: ["holdCamera": "1500"]).holdCamera, .millis(1500))
    XCTAssertNil(UseSmileIDSampleLaunchArguments(raw: ["holdCamera": "soon"]).holdCamera)
    XCTAssertNil(UseSmileIDSampleLaunchArguments(raw: ["holdCamera": "0"]).holdCamera)
  }

  func testAnUnrecognisedValueFallsBackToItsDefault() {
    let args = UseSmileIDSampleLaunchArguments(raw: ["scenario": "typo", "route": "sheet", "autostart": "bvn"])
    XCTAssertEqual(args.scenario, .normal)
    XCTAssertEqual(args.route, .fullscreen)
    XCTAssertNil(args.autostart)
  }

  /// The iOS mechanism: `-scenario expiredToken` lands in the argument domain, and only that domain is
  /// read — a value persisted under the same plain name is not a launch argument.
  func testTheArgumentsAreReadFromTheArgumentDomainOnly() throws {
    let suite = "usesmileid_sample_launch_test"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    let previous = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
    defer {
      defaults.setVolatileDomain(previous, forName: UserDefaults.argumentDomain)
      defaults.removePersistentDomain(forName: suite)
    }
    defaults.setVolatileDomain(
      ["scenario": "badRefresh", "theme": "partnerOverride", "route": "shell", "probes": "true", "autostart": "enhancedKyc", "holdCamera": "250"],
      forName: UserDefaults.argumentDomain
    )
    defaults.set("true", forKey: "seedJobs")

    let args = UseSmileIDSampleLaunchArguments(reading: defaults)
    XCTAssertEqual(args.scenario, .badRefresh)
    XCTAssertEqual(args.theme, .partnerOverride)
    XCTAssertEqual(args.route, .shell)
    XCTAssertTrue(args.probes)
    XCTAssertEqual(args.autostart, .enhancedKyc)
    XCTAssertEqual(args.holdCamera, .millis(250))
    XCTAssertFalse(args.seedJobs, "a persisted value must not read as a launch argument")
  }

  /// The spelling with no arguments is the spec's defaults, never a read, so no call site can mistake it.
  func testTheDefaultSpellingReadsNothing() {
    XCTAssertEqual(UseSmileIDSampleLaunchArguments(), UseSmileIDSampleLaunchArguments(raw: [:]))
  }

  /// A tag naming no language is dropped rather than rendering the default silently.
  func testAppLocaleBecomesALocaleOnlyWhenItNamesALanguage() {
    XCTAssertEqual(UseSmileIDSampleLaunchArguments(raw: ["appLocale": "fr-FR"]).locale?.identifier, "fr-FR")
    XCTAssertNil(UseSmileIDSampleLaunchArguments(raw: ["appLocale": "-"]).locale)
    XCTAssertNil(UseSmileIDSampleLaunchArguments(raw: ["appLocale": "zz-ZZ"]).locale, "not a known language")
    XCTAssertNil(UseSmileIDSampleLaunchArguments(raw: [:]).locale)
  }
}
