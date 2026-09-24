import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The four profile surfaces: reaching them, and the one act each of them performs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  late ProviderContainer container;

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    bool seedProfiles = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleLaunchArgsProvider.overrideWithValue(
            UseSmileIDSampleLaunchArgs(seedProfiles: seedProfiles),
          ),
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

  UseSmileIDSampleProfiles profiles() =>
      container.read(useSmileIDSampleProfilesProvider);

  group('the list', () {
    testWidgets('a plain launch shows no profile, only the create row', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.profiles);

      expect(byId(UseSmileIDSampleTestIds.profilesScreen), findsOne);
      expect(byId(UseSmileIDSampleTestIds.profileRow('p-1')), findsNothing);
      expect(byId(UseSmileIDSampleTestIds.profileRow('p-2')), findsNothing);
      expect(byId(UseSmileIDSampleTestIds.createProfile), findsOne);
    });

    // The list's ONLY marker of the active profile: no fill and no check, unlike the switch sheet.
    testWidgets('the active profile is named in its caption', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.profiles, seedProfiles: true);

      expect(find.text('Kwame Asante · active'), findsOne);
      expect(find.text('Amina Diallo'), findsOne);
    });

    testWidgets('seedProfiles is the only way to the design three', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.profiles, seedProfiles: true);

      for (final String id in <String>['p-1', 'p-2', 'p-3']) {
        expect(byId(UseSmileIDSampleTestIds.profileRow(id)), findsOne);
      }
    });

    testWidgets('a row opens that profile page', (WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.profiles, seedProfiles: true);
      await tester.tap(byId(UseSmileIDSampleTestIds.profileRow('p-2')));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.profileConfigScreen), findsOne);
      expect(find.text('Kazi Microlending'), findsWidgets);
    });
  });

  group('the profile page', () {
    testWidgets('its title is the profile name, not a static heading', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.profileConfig('p-3'),
        seedProfiles: true,
      );

      expect(find.text('PesaLink'), findsWidgets);
    });

    testWidgets('it edits the four fields the design lists', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.profileConfig('p-2'),
        seedProfiles: true,
      );

      for (final String field in <String>[
        'firstName',
        'lastName',
        'email',
        'phone',
      ]) {
        expect(
          byId(UseSmileIDSampleTestIds.profileConfigField(field)),
          findsOne,
          reason: field,
        );
      }
    });

    // On a profile that is not active the one CTA reads "Use this profile", so it saves and activates.
    testWidgets('saving stores the details and makes the profile active', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.profileConfig('p-2'),
        seedProfiles: true,
      );
      expect(profiles().activeId, 'p-1');

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.profileConfigField('email')),
        'amina@kazi.example',
      );
      await tester.pumpAndSettle();
      await tester.tap(byId(UseSmileIDSampleTestIds.profileConfigSave));
      await tester.pumpAndSettle();

      expect(profiles().activeId, 'p-2');
      expect(profiles().find('p-2')!.defaults.email, 'amina@kazi.example');
    });

    testWidgets('saving stores a trimmed callback URL the run then reads', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.profileConfig('p-2'),
        seedProfiles: true,
      );

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.profileConfigCallbackUrl),
        '  https://kazi.example/hooks ',
      );
      await tester.pumpAndSettle();
      await tester.tap(byId(UseSmileIDSampleTestIds.profileConfigSave));
      await tester.pumpAndSettle();

      expect(profiles().active?.callbackUrl, 'https://kazi.example/hooks');
    });

    testWidgets('the active profile saves its edits once there is one', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.profileConfig('p-1'),
        seedProfiles: true,
      );
      bool canSave() => tester
          .widget<UseSmileIDSampleButton>(find.byType(UseSmileIDSampleButton))
          .enabled;

      expect(find.text('Save changes'), findsOne);
      expect(canSave(), isFalse, reason: 'nothing changed yet');

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.profileConfigField('email')),
        'kwame@uptech.example',
      );
      await tester.pumpAndSettle();
      expect(canSave(), isTrue);
      await tester.tap(byId(UseSmileIDSampleTestIds.profileConfigSave));
      await tester.pumpAndSettle();

      expect(profiles().find('p-1')!.defaults.email, 'kwame@uptech.example');
      expect(profiles().activeId, 'p-1');
    });

    testWidgets('deleting asks first, then removes the profile', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.profileConfig('p-2'),
        seedProfiles: true,
      );

      await tester.ensureVisible(
        byId(UseSmileIDSampleTestIds.profileConfigDelete),
      );
      await tester.tap(byId(UseSmileIDSampleTestIds.profileConfigDelete));
      await tester.pumpAndSettle();
      expect(
        profiles().find('p-2'),
        isNotNull,
        reason: 'not before confirming',
      );

      await tester.tap(byId(UseSmileIDSampleTestIds.profileDeleteConfirm));
      await tester.pumpAndSettle();

      expect(profiles().find('p-2'), isNull);
      expect(byId(UseSmileIDSampleTestIds.profileConfigScreen), findsNothing);
    });

    testWidgets('a link to a profile this device does not hold goes back', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.profileConfig('p-1'));

      expect(byId(UseSmileIDSampleTestIds.profileConfigScreen), findsNothing);
    });
  });

  group('the new-profile sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.profiles, seedProfiles: true);
      await tester.tap(byId(UseSmileIDSampleTestIds.createProfile));
      await tester.pumpAndSettle();
    }

    testWidgets('it carries five fields and a confirm', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      expect(byId(UseSmileIDSampleTestIds.newProfileSheet), findsOne);
      for (final String id in <String>[
        UseSmileIDSampleTestIds.newProfileName,
        UseSmileIDSampleTestIds.newProfileFirstName,
        UseSmileIDSampleTestIds.newProfileLastName,
        UseSmileIDSampleTestIds.newProfileEmail,
        UseSmileIDSampleTestIds.newProfilePhone,
        UseSmileIDSampleTestIds.newProfileSave,
      ]) {
        expect(byId(id), findsOne, reason: id);
      }
    });

    // Email and phone never gate it, which is the whole of the sheet's validation.
    testWidgets('the confirm waits for a name and both names', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      // The button carries its own id INSIDE itself, so a descendant search from the id finds
      // nothing; the sheet has exactly one button, which is what this reads.
      bool canCreate() => tester
          .widget<UseSmileIDSampleButton>(find.byType(UseSmileIDSampleButton))
          .enabled;

      expect(canCreate(), isFalse);
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileName),
        'Karibu Pay',
      );
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileFirstName),
        'Njeri',
      );
      await tester.pumpAndSettle();
      expect(canCreate(), isFalse, reason: 'the family name is still missing');

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileLastName),
        'Wanjiku',
      );
      await tester.pumpAndSettle();
      expect(canCreate(), isTrue);
    });

    // The created profile is NOT made active; the confirmation carries that offer instead.
    testWidgets('creating confirms on the list and offers to activate', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileName),
        'Karibu Pay',
      );
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileFirstName),
        'Njeri',
      );
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.newProfileLastName),
        'Wanjiku',
      );
      await tester.pumpAndSettle();
      await tester.tap(byId(UseSmileIDSampleTestIds.newProfileSave));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.newProfileSheet), findsNothing);
      expect(find.text('Karibu Pay created'), findsOne);
      expect(find.text('Make active'), findsOne);
      expect(profiles().all, hasLength(4));
      expect(
        profiles().activeId,
        'p-1',
        reason: 'creating does not activate; the offer does',
      );

      await tester.tap(byId(UseSmileIDSampleTestIds.toastUndo));
      await tester.pumpAndSettle();

      expect(profiles().activeId, 'p-4');
      expect(find.text('Karibu Pay created'), findsNothing);
    });
  });

  group('the switch sheet', () {
    testWidgets('the products avatar opens it and a tap switches', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.products, seedProfiles: true);
      await tester.tap(byId(UseSmileIDSampleTestIds.profileAvatarButton));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.profileSwitchSheet), findsOne);

      // Through the row's own callback rather than a synthetic tap.
      tester
          .widgetList<UseSmileIDSampleProfileRow>(
            find.byType(UseSmileIDSampleProfileRow),
          )
          .firstWhere(
            (UseSmileIDSampleProfileRow row) => row.organisation == 'PesaLink',
          )
          .onTap();
      await tester.pumpAndSettle();

      expect(profiles().activeId, 'p-3');
      expect(
        byId(UseSmileIDSampleTestIds.profileSwitchSheet),
        findsNothing,
        reason: 'it switches immediately and closes itself',
      );
    });

    testWidgets('the settings row opens the list rather than a profile', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.settings);
      await tester.tap(byId(UseSmileIDSampleTestIds.profileSummary));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.profilesScreen), findsOne);
      expect(byId(UseSmileIDSampleTestIds.profileConfigScreen), findsNothing);
    });
  });
}
