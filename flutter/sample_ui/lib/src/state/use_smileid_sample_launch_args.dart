import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_product.dart';
import '../model/use_smileid_sample_result.dart';
import '../model/use_smileid_sample_scenario.dart';

/// How long the host holds the camera before handing off, so the SDK meets a contended device.
@immutable
sealed class UseSmileIDSampleHoldCamera {
  const UseSmileIDSampleHoldCamera();
}

/// Hold the camera for the whole run.
@immutable
final class UseSmileIDSampleHoldCameraKeep extends UseSmileIDSampleHoldCamera {
  /// Takes nothing: 'keep' is the whole instruction.
  const UseSmileIDSampleHoldCameraKeep();

  @override
  bool operator ==(Object other) => other is UseSmileIDSampleHoldCameraKeep;

  @override
  int get hashCode => (UseSmileIDSampleHoldCameraKeep).hashCode;
}

/// Hold the camera for a bounded number of milliseconds.
@immutable
final class UseSmileIDSampleHoldCameraMillis extends UseSmileIDSampleHoldCamera {
  /// Takes positive milliseconds; the parser rejects anything else.
  const UseSmileIDSampleHoldCameraMillis(this.value);

  /// The hold, in milliseconds.
  final int value;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleHoldCameraMillis && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// The canonical arguments from `spec/launch-args.json`; reading the cold-start link is the shell's job.
@immutable
class UseSmileIDSampleLaunchArgs {
  /// Every default is the plain launch: no fixtures, no probes, no autostart.
  const UseSmileIDSampleLaunchArgs({
    this.scenario = UseSmileIDSampleScenario.normal,
    this.theme = UseSmileIDSampleThemeScenario.brandDefault,
    this.route = UseSmileIDSampleFlowRoute.fullscreen,
    this.autostart,
    this.seedJobs = false,
    this.seedProfiles = false,
    this.probes = false,
    this.appLocale,
    this.holdCamera,
    this.noticeWindow,
  });

  /// The flow scenario.
  final UseSmileIDSampleScenario scenario;

  /// The theme scenario.
  final UseSmileIDSampleThemeScenario theme;

  /// Which entry route hosts the SDK flow.
  final UseSmileIDSampleFlowRoute route;

  /// A product to launch straight into, skipping the pre-flow forms.
  final UseSmileIDSampleProduct? autostart;

  /// Automation precondition only — seeds the design's fixture verifications.
  final bool seedJobs;

  /// The design's three profiles instead of the one empty starter; in memory, so per launch.
  final bool seedProfiles;

  /// Reveals the result card on a release build; always on in debug.
  final bool probes;

  /// An in-app locale override, because a device locale is not reliably scriptable.
  final String? appLocale;

  /// Whether the host acquires the camera before handing off.
  final UseSmileIDSampleHoldCamera? holdCamera;

  /// Seconds a transient notice stays before dismissing itself.
  final int? noticeWindow;

  /// The `scenario` argument's canonical name.
  static const String scenarioArg = 'scenario';

  /// The `theme` argument's canonical name.
  static const String themeArg = 'theme';

  /// The `route` argument's canonical name.
  static const String routeArg = 'route';

  /// The `autostart` argument's canonical name.
  static const String autostartArg = 'autostart';

  /// The `seedJobs` argument's canonical name.
  static const String seedJobsArg = 'seedJobs';

  /// The `seedProfiles` argument's canonical name.
  static const String seedProfilesArg = 'seedProfiles';

  /// The `probes` argument's canonical name.
  static const String probesArg = 'probes';

  /// The `appLocale` argument's canonical name.
  static const String appLocaleArg = 'appLocale';

  /// The `holdCamera` argument's canonical name.
  static const String holdCameraArg = 'holdCamera';

  /// The `noticeWindow` argument's canonical name.
  static const String noticeWindowArg = 'noticeWindow';

  /// The value `holdCamera` takes to hold for the whole run.
  static const String holdCameraKeep = 'keep';

  /// The ten names in the spec's own order, which the spec test compares against.
  static const List<String> names = <String>[
    scenarioArg,
    themeArg,
    routeArg,
    autostartArg,
    seedJobsArg,
    seedProfilesArg,
    probesArg,
    appLocaleArg,
    holdCameraArg,
    noticeWindowArg,
  ];

  /// An unrecognised value falls back to its default, which is safe only because the card reports it.
  static UseSmileIDSampleLaunchArgs from(Map<String, Object?> raw) {
    const UseSmileIDSampleLaunchArgs defaults = UseSmileIDSampleLaunchArgs();
    return UseSmileIDSampleLaunchArgs(
      scenario: UseSmileIDSampleScenario.byId(_string(raw, scenarioArg)) ?? defaults.scenario,
      theme: UseSmileIDSampleThemeScenario.byId(_string(raw, themeArg)) ?? defaults.theme,
      route: UseSmileIDSampleFlowRoute.byId(_string(raw, routeArg)) ?? defaults.route,
      autostart: UseSmileIDSampleProduct.byId(_string(raw, autostartArg)),
      seedJobs: _boolean(raw, seedJobsArg) ?? defaults.seedJobs,
      seedProfiles: _boolean(raw, seedProfilesArg) ?? defaults.seedProfiles,
      probes: _boolean(raw, probesArg) ?? defaults.probes,
      appLocale: _string(raw, appLocaleArg),
      holdCamera: _holdCamera(raw),
      noticeWindow: _noticeWindow(raw),
    );
  }

  /// Everything a cold-start link carries, read from its query string.
  static UseSmileIDSampleLaunchArgs fromUri(Uri? uri) =>
      from(<String, Object?>{...?uri?.queryParameters});

  static String? _string(Map<String, Object?> raw, String name) {
    final String value = raw[name]?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// A link's query parameter arrives as a String, which is the only form that path has.
  static bool? _boolean(Map<String, Object?> raw, String name) {
    final Object? value = raw[name];
    if (value is bool) {
      return value;
    }
    final String? text = _string(raw, name)?.toLowerCase();
    return switch (text) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  /// Null rather than zero for a rejected value: zero would dismiss the notice before it rendered.
  static int? _noticeWindow(Map<String, Object?> raw) {
    final int? seconds = int.tryParse(_string(raw, noticeWindowArg) ?? '');
    return seconds != null && seconds > 0 ? seconds : null;
  }

  static UseSmileIDSampleHoldCamera? _holdCamera(Map<String, Object?> raw) {
    final String? value = _string(raw, holdCameraArg);
    if (value == null) {
      return null;
    }
    if (value.toLowerCase() == holdCameraKeep) {
      return const UseSmileIDSampleHoldCameraKeep();
    }
    final int? millis = int.tryParse(value);
    return millis != null && millis > 0 ? UseSmileIDSampleHoldCameraMillis(millis) : null;
  }

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleLaunchArgs &&
      other.scenario == scenario &&
      other.theme == theme &&
      other.route == route &&
      other.autostart == autostart &&
      other.seedJobs == seedJobs &&
      other.seedProfiles == seedProfiles &&
      other.probes == probes &&
      other.appLocale == appLocale &&
      other.holdCamera == holdCamera &&
      other.noticeWindow == noticeWindow;

  @override
  int get hashCode => Object.hash(
    scenario,
    theme,
    route,
    autostart,
    seedJobs,
    seedProfiles,
    probes,
    appLocale,
    holdCamera,
    noticeWindow,
  );
}
