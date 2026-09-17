import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

void main() {
  late List<Map<String, Object?>> args;

  setUpAll(() => args = objects(spec('launch-args.json')['args']));

  test('the canonical names match the spec', () {
    final List<String> expected = args
        .map((Map<String, Object?> it) => it['name']! as String)
        .toList();
    expect(expected, isNotEmpty, reason: 'extracted no launch arguments');
    expect(UseSmileIDSampleLaunchArgs.names, expected);
  });

  test('the defaults match the spec', () {
    const UseSmileIDSampleLaunchArgs defaults = UseSmileIDSampleLaunchArgs();
    final Map<String, Object?> ours = <String, Object?>{
      UseSmileIDSampleLaunchArgs.scenarioArg: defaults.scenario.id,
      UseSmileIDSampleLaunchArgs.themeArg: defaults.theme.id,
      UseSmileIDSampleLaunchArgs.routeArg: defaults.route.id,
      UseSmileIDSampleLaunchArgs.autostartArg: defaults.autostart?.id,
      UseSmileIDSampleLaunchArgs.seedJobsArg: defaults.seedJobs,
      UseSmileIDSampleLaunchArgs.seedProfilesArg: defaults.seedProfiles,
      UseSmileIDSampleLaunchArgs.probesArg: defaults.probes,
      UseSmileIDSampleLaunchArgs.appLocaleArg: defaults.appLocale,
      UseSmileIDSampleLaunchArgs.holdCameraArg: defaults.holdCamera,
      UseSmileIDSampleLaunchArgs.noticeWindowArg: defaults.noticeWindow,
    };
    final Map<String, Object?> theirs = <String, Object?>{
      for (final Map<String, Object?> arg in args)
        arg['name']! as String: arg['default'],
    };
    expect(ours, theirs);
  });

  test('an empty launch is the declared defaults', () {
    expect(
      UseSmileIDSampleLaunchArgs.from(const <String, Object?>{}),
      const UseSmileIDSampleLaunchArgs(),
    );
  });

  test('a launch with no arguments seeds nothing', () {
    const UseSmileIDSampleLaunchArgs plain = UseSmileIDSampleLaunchArgs();
    expect(plain.seedJobs, isFalse);
    expect(plain.seedProfiles, isFalse);
    expect(plain.probes, isFalse);
    expect(plain.autostart, isNull);
  });

  test('every argument is read from its canonical name', () {
    final UseSmileIDSampleLaunchArgs parsed =
        UseSmileIDSampleLaunchArgs.from(const <String, Object?>{
          UseSmileIDSampleLaunchArgs.scenarioArg: 'expiredToken',
          UseSmileIDSampleLaunchArgs.themeArg: 'clashingHost',
          UseSmileIDSampleLaunchArgs.routeArg: 'shell',
          UseSmileIDSampleLaunchArgs.autostartArg: 'biometricKyc',
          UseSmileIDSampleLaunchArgs.seedJobsArg: true,
          UseSmileIDSampleLaunchArgs.seedProfilesArg: true,
          UseSmileIDSampleLaunchArgs.probesArg: true,
          UseSmileIDSampleLaunchArgs.appLocaleArg: 'fr-FR',
          UseSmileIDSampleLaunchArgs.holdCameraArg: 'keep',
          UseSmileIDSampleLaunchArgs.noticeWindowArg: '60',
        });
    expect(parsed.scenario, UseSmileIDSampleScenario.expiredToken);
    expect(parsed.theme, UseSmileIDSampleThemeScenario.clashingHost);
    expect(parsed.route, UseSmileIDSampleFlowRoute.shell);
    expect(parsed.autostart, UseSmileIDSampleProduct.biometricKyc);
    expect(parsed.seedJobs, isTrue);
    expect(parsed.seedProfiles, isTrue);
    expect(parsed.probes, isTrue);
    expect(parsed.appLocale, 'fr-FR');
    expect(parsed.holdCamera, const UseSmileIDSampleHoldCameraKeep());
    expect(parsed.noticeWindow, 60);
  });

  test(
    'a cold-start link carries the same nine names through its query string',
    () {
      final UseSmileIDSampleLaunchArgs
      parsed = UseSmileIDSampleLaunchArgs.fromUri(
        Uri.parse(
          'usesmileid-sample-flutter://run?scenario=badRefresh&route=shell&seedJobs=true',
        ),
      );
      expect(parsed.scenario, UseSmileIDSampleScenario.badRefresh);
      expect(parsed.route, UseSmileIDSampleFlowRoute.shell);
      expect(parsed.seedJobs, isTrue);
      expect(parsed.seedProfiles, isFalse);
    },
  );

  test('the boolean arguments read either form a launch can deliver', () {
    bool seeds(Object? value) => UseSmileIDSampleLaunchArgs.from(
      <String, Object?>{'seedJobs': value},
    ).seedJobs;
    expect(seeds(true), isTrue);
    expect(seeds('TRUE'), isTrue);
    expect(seeds('false'), isFalse);
    expect(seeds('yes'), isFalse);
  });

  test('notice window takes positive seconds only', () {
    int? window(String value) => UseSmileIDSampleLaunchArgs.from(
      <String, Object?>{'noticeWindow': value},
    ).noticeWindow;
    expect(window('60'), 60);
    expect(window('soon'), isNull);
    expect(window('0'), isNull);
    expect(window('-5'), isNull);
  });

  test('hold camera accepts milliseconds as well as keep', () {
    expect(
      UseSmileIDSampleLaunchArgs.from(const <String, Object?>{
        'holdCamera': '1500',
      }).holdCamera,
      const UseSmileIDSampleHoldCameraMillis(1500),
    );
    expect(
      UseSmileIDSampleLaunchArgs.from(const <String, Object?>{
        'holdCamera': 'soon',
      }).holdCamera,
      isNull,
    );
  });

  test('an unrecognised value falls back to its default', () {
    final UseSmileIDSampleLaunchArgs parsed = UseSmileIDSampleLaunchArgs.from(
      const <String, Object?>{'scenario': 'typo', 'route': 'sheet'},
    );
    expect(parsed.scenario, UseSmileIDSampleScenario.normal);
    expect(parsed.route, UseSmileIDSampleFlowRoute.fullscreen);
  });

  test('the retired sandbox argument is neither declared nor read', () {
    expect(UseSmileIDSampleLaunchArgs.names, isNot(contains('sandbox')));
    expect(
      UseSmileIDSampleLaunchArgs.from(const <String, Object?>{
        'sandbox': false,
      }),
      const UseSmileIDSampleLaunchArgs(),
    );
  });
}
