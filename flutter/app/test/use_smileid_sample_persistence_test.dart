import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// Settings survive a restart, which is the whole claim, so a restart is what the tests perform.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A fresh process: the store keeps its contents, and everything above it is built again.
  Future<UseSmileIDSamplePreferencesSettingsRepository> restart() async =>
      UseSmileIDSamplePreferencesSettingsRepository.open();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a first launch reads the plain defaults', () async {
    expect(
      await (await restart()).read(),
      equalsSettings(const UseSmileIDSampleSettings()),
    );
  });

  test('a switch survives the process that set it', () async {
    await (await restart()).setSetting(
      UseSmileIDSampleSetting.previewStep,
      false,
    );

    expect((await (await restart()).read()).previewStep, isFalse);
  });

  test('the store writes the keys the four apps share', () async {
    await (await restart()).setSetting(UseSmileIDSampleSetting.darkMode, true);

    final SharedPreferences raw = await SharedPreferences.getInstance();
    expect(raw.getBool(UseSmileIDSampleSettingsKeys.darkMode), isTrue);
    expect(
      raw.getKeys(),
      containsAll(<String>[
        UseSmileIDSampleSettingsKeys.enhancedSmartSelfie,
        UseSmileIDSampleSettingsKeys.agentMode,
        UseSmileIDSampleSettingsKeys.darkMode,
        UseSmileIDSampleSettingsKeys.consentStep,
        UseSmileIDSampleSettingsKeys.instructionsStep,
        UseSmileIDSampleSettingsKeys.previewStep,
      ]),
    );
  });

  // The mutex is the reason a write goes through the model rather than setting one key: turning
  // agent mode on has to turn enhanced liveness off, and BOTH have to reach the disk.
  test('turning on agent mode stores enhanced liveness off as well', () async {
    final UseSmileIDSamplePreferencesSettingsRepository store = await restart();
    expect((await store.read()).enhancedSmartSelfie, isTrue);

    await store.setSetting(UseSmileIDSampleSetting.agentMode, true);

    final UseSmileIDSampleSettings reread = await (await restart()).read();
    expect(reread.agentMode, isTrue);
    expect(reread.enhancedSmartSelfie, isFalse);
  });

  // A store written by an older build, or by hand, can hold the pair the SDK refuses. Normalising
  // only on the way in would hand that pair straight to the screen on the next launch.
  test('a stored pair the SDK refuses is dropped on the way out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UseSmileIDSampleSettingsKeys.agentMode: true,
      UseSmileIDSampleSettingsKeys.enhancedSmartSelfie: true,
    });

    final UseSmileIDSampleSettings read = await (await restart()).read();
    expect(read.agentMode, isTrue);
    expect(read.enhancedSmartSelfie, isFalse);
  });

  testWidgets('the app opens in the appearance the store held', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UseSmileIDSampleSettingsKeys.darkMode: true,
    });
    final UseSmileIDSamplePreferencesSettingsRepository store = await restart();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(store),
          useSmileIDSampleStoredSettingsProvider.overrideWithValue(
            await store.read(),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          darkTheme: UseSmileIDSampleTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: useSmileIDSampleRouter(),
        ),
      ),
    );
    await tester.pump();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(useSmileIDSampleSettingsProvider).darkMode, isTrue);
  });

  testWidgets('the seeded profiles are reachable only through the argument', (
    WidgetTester tester,
  ) async {
    Future<UseSmileIDSampleProfiles> profilesFor(
      UseSmileIDSampleLaunchArgs args,
    ) async {
      final ProviderContainer container = ProviderContainer(
        overrides: [useSmileIDSampleLaunchArgsProvider.overrideWithValue(args)],
      );
      addTearDown(container.dispose);
      return container.read(useSmileIDSampleProfilesProvider);
    }

    expect(
      (await profilesFor(const UseSmileIDSampleLaunchArgs())).all,
      hasLength(1),
    );
    expect(
      (await profilesFor(
        const UseSmileIDSampleLaunchArgs(seedProfiles: true),
      )).all,
      hasLength(3),
    );
  });
}

/// Compares two settings by their six switches, which is all a settings value is.
Matcher equalsSettings(UseSmileIDSampleSettings expected) =>
    predicate<UseSmileIDSampleSettings>(
      (UseSmileIDSampleSettings actual) => UseSmileIDSampleSetting.values.every(
        (UseSmileIDSampleSetting setting) =>
            actual[setting] == expected[setting],
      ),
      'the same six switches',
    );
