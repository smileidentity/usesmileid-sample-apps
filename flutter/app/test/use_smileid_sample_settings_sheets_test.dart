import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_app.dart';

import 'support/use_smileid_sample_test_njia.dart';
import 'support/use_smileid_sample_test_session.dart';

/// The settings sheets as steps over settings: a pick is kept and closes its sheet; the drawer stays open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  late ProviderContainer container;

  Future<void> pumpAt(WidgetTester tester, String link) async {
    final UseSmileIDSamplePreferencesSettingsRepository settings =
        await UseSmileIDSamplePreferencesSettingsRepository.open();
    final UseSmileIDSamplePreferencesJobsRepository jobs =
        await UseSmileIDSamplePreferencesJobsRepository.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...useSmileIDSampleTestNjia(),
          ...useSmileIDSampleLinkedSessionOverrides(),
          useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(
            settings,
          ),
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
        ],
        child: UseSmileIDSampleApp(launchLink: Uri.parse(link)),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  UseSmileIDSampleSettings settings() =>
      container.read(useSmileIDSampleSettingsProvider);

  Future<void> pick(WidgetTester tester, String id) async {
    // Centred: a drag that starts on a tappable row loses its touch slop, so a scrolled-to row can sit at the edge.
    await Scrollable.ensureVisible(tester.element(byId(id)), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(byId(id));
    await tester.pumpAndSettle();
  }

  testWidgets('a capture mode picked is kept, and the sheet closes', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.captureMode);
    expect(byId(UseSmileIDSampleTestIds.captureModeSheet), findsOne);

    await pick(
      tester,
      UseSmileIDSampleTestIds.captureModeOption(
        UseSmileIDSampleCaptureMode.manual.id,
      ),
    );

    expect(settings().captureMode, UseSmileIDSampleCaptureMode.manual);
    expect(byId(UseSmileIDSampleTestIds.captureModeSheet), findsNothing);
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.settings);
  });

  testWidgets('a submission picked is kept, and the sheet closes', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.submission);
    expect(byId(UseSmileIDSampleTestIds.submissionSheet), findsOne);

    await pick(
      tester,
      UseSmileIDSampleTestIds.submissionOption(
        UseSmileIDSampleSubmission.skip.id,
      ),
    );

    expect(settings().submission, UseSmileIDSampleSubmission.skip);
    expect(byId(UseSmileIDSampleTestIds.submissionSheet), findsNothing);
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.settings);
  });

  testWidgets('an appearance picked is kept, and the sheet closes', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.appearance);
    expect(byId(UseSmileIDSampleTestIds.appearanceSheet), findsOne);

    await pick(
      tester,
      UseSmileIDSampleTestIds.appearanceOption(
        UseSmileIDSampleAppearance.dark.id,
      ),
    );

    expect(settings().appearance, UseSmileIDSampleAppearance.dark);
    expect(byId(UseSmileIDSampleTestIds.appearanceSheet), findsNothing);
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.settings);
  });

  testWidgets('a language picked is kept, and the sheet closes', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.language);
    expect(byId(UseSmileIDSampleTestIds.languageSheet), findsOne);

    await pick(
      tester,
      UseSmileIDSampleTestIds.languageOption(UseSmileIDSampleLanguage.fr.id),
    );

    expect(settings().language, UseSmileIDSampleLanguage.fr);
    expect(byId(UseSmileIDSampleTestIds.languageSheet), findsNothing);
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.settings);
  });

  testWidgets('a scenario picked in the drawer is kept, and the drawer stays', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.scenarioDrawer);

    await pick(
      tester,
      UseSmileIDSampleTestIds.scenarioItem(
        UseSmileIDSampleScenario.expiredToken.id,
      ),
    );

    expect(
      container.read(useSmileIDSampleScenarioProvider).scenario,
      UseSmileIDSampleScenario.expiredToken,
    );
    expect(byId(UseSmileIDSampleTestIds.scenarioDrawer), findsOne);
    expect(
      useSmileIDSampleTestTop(tester),
      UseSmileIDSampleStep.scenarioDrawer,
    );
  });

  testWidgets('the settings rows open their sheets over settings', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.settings);

    await tester.scrollUntilVisible(
      byId(UseSmileIDSampleTestIds.settingCaptureMode),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await pick(tester, UseSmileIDSampleTestIds.settingCaptureMode);

    expect(byId(UseSmileIDSampleTestIds.captureModeSheet), findsOne);
    expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.captureMode);
  });
}
