import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/catalogue/use_smileid_sample_catalogue_providers.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_app.dart';
import 'support/use_smileid_sample_test_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  tearDown(() => useSmileIDSampleCatalogueLanguage = null);

  Future<void> pumpApp(
    WidgetTester tester,
    UseSmileIDSampleLanguage language,
  ) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[
      Locale('en', 'GB'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.localeTestValue = const Locale('en', 'GB');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final UseSmileIDSamplePreferencesSettingsRepository settings =
        await UseSmileIDSamplePreferencesSettingsRepository.open();
    final UseSmileIDSamplePreferencesJobsRepository jobs =
        await UseSmileIDSamplePreferencesJobsRepository.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...useSmileIDSampleLinkedSessionOverrides(),
          useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(
            settings,
          ),
          useSmileIDSampleStoredSettingsProvider.overrideWithValue(
            UseSmileIDSampleSettings(language: language),
          ),
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
        ],
        child: const UseSmileIDSampleApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a picked language is the one the catalogue asks in', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, UseSmileIDSampleLanguage.fr);
    expect(useSmileIDSampleCatalogueLocale(), 'fr');
  });

  testWidgets("Material's own text follows the picked language", (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, UseSmileIDSampleLanguage.fr);
    final BuildContext context = tester.element(find.byType(Navigator).first);
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Retour');
    expect(Directionality.of(context), TextDirection.ltr);
  });

  testWidgets('Arabic lays Material out right to left', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, UseSmileIDSampleLanguage.ar);
    final BuildContext context = tester.element(find.byType(Navigator).first);
    expect(Directionality.of(context), TextDirection.rtl);
    expect(MaterialLocalizations.of(context).backButtonTooltip, isNot('Back'));
  });

  testWidgets('System asks in the device locale', (WidgetTester tester) async {
    await pumpApp(tester, UseSmileIDSampleLanguage.system);
    expect(useSmileIDSampleCatalogueLocale(), 'en-GB');
  });
}
