import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_profiles_repository.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_forms.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// A profile is who a job runs as: the form fills from it, Continue keeps into it, and it outlives the process.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  late ProviderContainer container;
  late UseSmileIDSampleMemoryProfilesRepository stored;

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    bool seedProfiles = false,
    UseSmileIDSampleProfiles? existing,
  }) async {
    stored = UseSmileIDSampleMemoryProfilesRepository();
    if (existing != null) {
      await stored.write(existing);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleLaunchArgsProvider.overrideWithValue(
            UseSmileIDSampleLaunchArgs(seedProfiles: seedProfiles),
          ),
          useSmileIDSampleProfilesRepositoryProvider.overrideWithValue(stored),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(initialLocation: location),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  Future<void> type(WidgetTester tester, String field, String value) => tester
      .enterText(byId(UseSmileIDSampleTestIds.userDetailsField(field)), value);

  Future<void> fillAndContinue(WidgetTester tester) async {
    await type(tester, 'firstName', 'Ada');
    await type(tester, 'lastName', 'Okafor');
    await type(tester, 'email', 'ada@kobo.example');
    await tester.pumpAndSettle();
  }

  testWidgets('the first run keeps what was typed as the active profile', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
    );
    await type(tester, 'organisation', 'Kobo Bank');
    await fillAndContinue(tester);
    expect(find.text('Save as a new profile'), findsOne);

    await tester.tap(byId(UseSmileIDSampleTestIds.userDetailsContinue));
    await tester.pumpAndSettle();

    final UseSmileIDSampleProfile? active = stored.read().active;
    expect(active?.organisation, 'Kobo Bank');
    expect(active?.defaults.firstName, 'Ada');
  });

  testWidgets('the switch off keeps nothing', (WidgetTester tester) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
    );
    await fillAndContinue(tester);
    await tester.tap(byId(UseSmileIDSampleTestIds.rememberDetailsSwitch));
    await tester.pumpAndSettle();

    await tester.tap(byId(UseSmileIDSampleTestIds.userDetailsContinue));
    await tester.pumpAndSettle();

    expect(stored.read().all, isEmpty);
  });

  testWidgets('a stored profile fills the form a product opens', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.products,
      existing: UseSmileIDSampleProfiles(<UseSmileIDSampleProfile>[
        const UseSmileIDSampleProfile(
          id: 'p-1',
          organisation: 'Kobo Bank',
          defaults: UseSmileIDSampleUserDetails(
            firstName: 'Ada',
            lastName: 'Okafor',
          ),
        ),
      ]),
    );
    await tester.tap(
      byId(UseSmileIDSampleTestIds.productCard('smartSelfieEnrollment')),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(useSmileIDSampleFormsProvider).userDetails.firstName,
      'Ada',
    );
    expect(find.text('Kobo Bank'), findsOne);
  });

  testWidgets('a seeded launch stores nothing', (WidgetTester tester) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
      seedProfiles: true,
    );
    await tester.pumpAndSettle();
    await type(tester, 'email', 'kwame@uptech.example');
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.userDetailsContinue));
    await tester.pumpAndSettle();

    expect(stored.read().all, isEmpty);
  });

  testWidgets(
    '"New profile" from the form starts from the typing and runs as it',
    (WidgetTester tester) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
        seedProfiles: true,
      );
      await type(tester, 'firstName', 'Njeri');
      await type(tester, 'lastName', 'Wanjiku');
      await tester.pumpAndSettle();
      await tester.tap(byId(UseSmileIDSampleTestIds.userDetailsProfile));
      await tester.pumpAndSettle();
      await tester.tap(byId(UseSmileIDSampleTestIds.profileSwitchNew));
      await tester.pumpAndSettle();

      expect(find.text('Njeri'), findsWidgets);
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileName),
        'Karibu Pay',
      );
      await tester.pumpAndSettle();
      await tester.tap(byId(UseSmileIDSampleTestIds.newProfileSave));
      await tester.pumpAndSettle();

      final UseSmileIDSampleProfiles profiles = container.read(
        useSmileIDSampleProfilesProvider,
      );
      expect(profiles.active?.organisation, 'Karibu Pay');
      expect(profiles.active?.defaults.lastName, 'Wanjiku');
    },
  );

  testWidgets('sign-out asks first, then deletes every profile', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.settings,
      existing: UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures()),
    );
    await tester.scrollUntilVisible(
      byId(UseSmileIDSampleTestIds.signOut),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(byId(UseSmileIDSampleTestIds.signOut));
    await tester.pumpAndSettle();
    expect(stored.read().all, hasLength(3), reason: 'not before confirming');

    await tester.tap(byId(UseSmileIDSampleTestIds.signOutConfirm));
    await tester.pumpAndSettle();

    expect(stored.read().all, isEmpty);
  });

  group('the preferences store', () {
    test('profiles written by one store are read by the next', () async {
      final UseSmileIDSampleProfiles profiles = UseSmileIDSampleProfiles(
        UseSmileIDSampleProfiles.fixtures(),
        'p-2',
      );
      await (await UseSmileIDSamplePreferencesProfilesRepository.open()).write(
        profiles,
      );

      final UseSmileIDSampleProfiles read =
          (await UseSmileIDSamplePreferencesProfilesRepository.open()).read();
      expect(read.all, profiles.all);
      expect(read.activeId, 'p-2');
    });

    test(
      'an install holding only the released keys reads as no profiles',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'dark_mode': true,
        });

        expect(
          (await UseSmileIDSamplePreferencesProfilesRepository.open())
              .read()
              .all,
          isEmpty,
        );
        final UseSmileIDSampleSettings settings =
            await (await UseSmileIDSamplePreferencesSettingsRepository.open())
                .read();
        expect(settings.darkMode, isTrue, reason: 'released settings survive');
      },
    );

    test(
      'a value of another type under the key reads as no profiles',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          useSmileIDSampleProfilesKey: 7,
        });

        expect(
          (await UseSmileIDSamplePreferencesProfilesRepository.open())
              .read()
              .all,
          isEmpty,
        );
      },
    );
  });
}
