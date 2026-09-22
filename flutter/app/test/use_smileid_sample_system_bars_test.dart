import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid/usesmileid.dart' show UseSmileIDBuilder;
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_forms.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_app.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// Status-bar contrast in both presentations, whatever the device's brightness.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// A style no screen draws: `latestStyle` is static, so each case writes over this or fails.
  const SystemUiOverlayStyle unset = SystemUiOverlayStyle(
    statusBarColor: Colors.red,
  );

  Future<void> forgetBars(WidgetTester tester) async {
    SystemChrome.setSystemUIOverlayStyle(unset);
    await tester.idle();
    expect(SystemChrome.latestStyle, unset);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    required bool darkMode,
    required Brightness device,
    String? at,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = device;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await forgetBars(tester);
    final UseSmileIDSamplePreferencesSettingsRepository settings =
        await UseSmileIDSamplePreferencesSettingsRepository.open();
    final UseSmileIDSamplePreferencesJobsRepository jobs =
        await UseSmileIDSamplePreferencesJobsRepository.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(
            settings,
          ),
          useSmileIDSampleStoredSettingsProvider.overrideWithValue(
            UseSmileIDSampleSettings(darkMode: darkMode),
          ),
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
        ],
        child: UseSmileIDSampleApp(initialLocation: at),
      ),
    );
    await tester.pumpAndSettle();
  }

  Brightness themeBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Navigator).first)).brightness;

  /// Both platforms' icons contrast with a page of this brightness.
  void expectStyle(SystemUiOverlayStyle? style, {required bool dark}) {
    expect(style, isNotNull);
    expect(
      style!.statusBarIconBrightness,
      dark ? Brightness.light : Brightness.dark,
    );
    expect(
      style.statusBarBrightness,
      dark ? Brightness.dark : Brightness.light,
    );
    expect(
      style.systemNavigationBarIconBrightness,
      dark ? Brightness.light : Brightness.dark,
    );
    expect(style.statusBarColor, Colors.transparent);
  }

  /// The page follows the switch and the bars last drawn contrast with it.
  void expectBars(WidgetTester tester, {required bool dark}) {
    expect(themeBrightness(tester), dark ? Brightness.dark : Brightness.light);
    expectStyle(SystemChrome.latestStyle, dark: dark);
  }

  testWidgets('a light app on a dark device draws dark icons at a tab root', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, darkMode: false, device: Brightness.dark);

    expectBars(tester, dark: false);
  });

  testWidgets('a dark app on a light device draws light icons when pushed', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      darkMode: true,
      device: Brightness.light,
      at: UseSmileIDSampleRoutes.licenses,
    );

    expectBars(tester, dark: true);
  });

  testWidgets('a light app on a dark device draws dark icons over a sheet', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      darkMode: false,
      device: Brightness.dark,
      at: UseSmileIDSampleRoutes.scenarioDrawer,
    );

    expect(find.byType(BottomSheet), findsOneWidget);
    expectBars(tester, dark: false);
  });

  testWidgets('a dark app on a light device draws light icons over a sheet', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      darkMode: true,
      device: Brightness.light,
      at: UseSmileIDSampleRoutes.scenarioDrawer,
    );

    expect(find.byType(BottomSheet), findsOneWidget);
    expectBars(tester, dark: true);
  });

  testWidgets('a dark app on a light device hands the SDK the dark theme', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, darkMode: true, device: Brightness.light);
    final BuildContext context = tester.element(find.byType(Navigator).first);
    final UseSmileIDSampleFormsNotifier forms = ProviderScope.containerOf(
      context,
    ).read(useSmileIDSampleFormsProvider.notifier);
    forms
      ..setUserField(UseSmileIDSampleUserField.firstName, 'Ada')
      ..setUserField(UseSmileIDSampleUserField.lastName, 'Lovelace')
      ..setUserField(UseSmileIDSampleUserField.email, 'ada@example.com');
    // Forgotten after the products tab drew dark, so only the SDK route's frame can draw it again.
    await forgetBars(tester);
    GoRouter.of(context).go(
      UseSmileIDSampleRoutes.sdkFlow(
        UseSmileIDSampleProduct.smartSelfieEnrollment.id,
      ),
    );
    await tester.pumpAndSettle();

    // The SDK renders nothing under `flutter test`, so this asserts what it is handed.
    final BuildContext sdk = tester.element(find.byType(UseSmileIDBuilder));
    expect(MediaQuery.platformBrightnessOf(sdk), Brightness.dark);
    expectStyle(
      sdk
          .findAncestorWidgetOfExactType<
            AnnotatedRegion<SystemUiOverlayStyle>
          >()
          ?.value,
      dark: true,
    );
    expectBars(tester, dark: true);
  });
}
