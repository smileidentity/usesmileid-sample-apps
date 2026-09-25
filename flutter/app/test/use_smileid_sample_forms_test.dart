import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_forms.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The two pre-flow forms, their two picker sheets, and the order a product tap starts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  late ProviderContainer container;

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      ProviderScope(
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

  UseSmileIDSampleForms forms() =>
      container.read(useSmileIDSampleFormsProvider);

  bool continueEnabled(WidgetTester tester, String id) => tester
      .widgetList<UseSmileIDSampleButton>(find.byType(UseSmileIDSampleButton))
      .last
      .enabled;

  group('the journey', () {
    testWidgets('a product tap opens the consent form, titled by product', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.products);
      await tester.tap(
        byId(UseSmileIDSampleTestIds.productCard('smartSelfieEnrollment')),
      );
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.userDetailsScreen), findsOne);
      expect(find.text('SmartSelfie Enrollment'), findsOne);
    });

    // The two SmartSelfie products need no document, so they skip the ID form entirely.
    testWidgets('a SmartSelfie product skips the ID form', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.consentDetailsForm('smartSelfieEnrollment'),
      );
      await _fillUserDetails(tester, byId);
      await tester.tap(byId(UseSmileIDSampleTestIds.userDetailsContinue));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.kycFormScreen), findsNothing);
    });

    testWidgets('a document product goes on to the ID form', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
      );
      await _fillUserDetails(tester, byId);
      await tester.tap(byId(UseSmileIDSampleTestIds.userDetailsContinue));
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.kycFormScreen), findsOne);
    });
  });

  group('the consent form', () {
    testWidgets('with no profile it opens empty and offers to make one', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
      );

      expect(forms().userDetails.firstName, isEmpty);
      expect(find.text('No profile yet'), findsOne);
      expect(
        byId(UseSmileIDSampleTestIds.userDetailsField('organisation')),
        findsOne,
      );
    });

    // The SDK needs a contact even though the design labels both contact rows optional, so the
    // hint names all three and Continue waits for one of them.
    testWidgets('it asks for both names and one contact', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
      );

      expect(
        find.text('Required: first name, last name, an email or phone number.'),
        findsOne,
      );
      expect(
        continueEnabled(tester, UseSmileIDSampleTestIds.userDetailsContinue),
        isFalse,
      );

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.userDetailsField('firstName')),
        'Njeri',
      );
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.userDetailsField('lastName')),
        'Wanjiku',
      );
      await tester.pumpAndSettle();
      expect(
        continueEnabled(tester, UseSmileIDSampleTestIds.userDetailsContinue),
        isFalse,
        reason: 'a contact is still outstanding',
      );

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.userDetailsField('phone')),
        '+254700000000',
      );
      await tester.pumpAndSettle();
      expect(
        continueEnabled(tester, UseSmileIDSampleTestIds.userDetailsContinue),
        isTrue,
        reason: 'either contact will do',
      );
    });

    testWidgets('the save switch appears only once the form is complete', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.consentDetailsForm('biometricKyc'),
      );
      expect(byId(UseSmileIDSampleTestIds.rememberDetailsSwitch), findsNothing);

      await _fillUserDetails(tester, byId);

      expect(byId(UseSmileIDSampleTestIds.rememberDetailsSwitch), findsOne);
      expect(find.text('Tap any field to edit.'), findsOne);
    });
  });

  test('a new run never carries the last run\'s ID details', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final UseSmileIDSampleFormsNotifier notifier = container.read(
      useSmileIDSampleFormsProvider.notifier,
    );
    notifier
      ..setCountry(UseSmileIDSampleCountry.ke)
      ..setIdType(UseSmileIDSampleIdType.nationalId)
      ..setIdNumber('12345678');

    notifier.startRun(null);

    final UseSmileIDSampleIdDetails details = container
        .read(useSmileIDSampleFormsProvider)
        .idDetails;
    expect(details.country, isNull);
    expect(details.idType, isNull);
    expect(details.idNumber, isEmpty);
  });

  group('the ID form', () {
    Future<void> openForm(WidgetTester tester) =>
        pumpAt(tester, UseSmileIDSampleRoutes.idDetailsForm('biometricKyc'));

    testWidgets('the ID type waits for a country, and says so', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      expect(find.text('Choose a country first'), findsOne);
      expect(
        tester
            .widget<UseSmileIDSampleSelectTrigger>(
              find.byType(UseSmileIDSampleSelectTrigger).last,
            )
            .enabled,
        isFalse,
      );
    });

    testWidgets('choosing a country opens the types that country issues', (
      WidgetTester tester,
    ) async {
      await openForm(tester);
      await tester.tap(byId(UseSmileIDSampleTestIds.countryTrigger));
      await tester.pumpAndSettle();
      expect(byId(UseSmileIDSampleTestIds.countrySheet), findsOne);

      await _selectOption(tester, 'Ghana');

      expect(forms().idDetails.country, UseSmileIDSampleCountry.gh);
      await tester.tap(byId(UseSmileIDSampleTestIds.idTypeTrigger));
      await tester.pumpAndSettle();

      // Ghana issues a Voter ID but no licence, which is the point of the per-country table.
      expect(find.text('Voter ID'), findsOne);
      expect(find.text("Driver's licence"), findsNothing);
    });

    // The types the old country offered may not apply to the new one.
    testWidgets('changing the country clears the chosen type', (
      WidgetTester tester,
    ) async {
      await openForm(tester);
      await tester.tap(byId(UseSmileIDSampleTestIds.countryTrigger));
      await tester.pumpAndSettle();
      await _selectOption(tester, 'Kenya');
      await tester.tap(byId(UseSmileIDSampleTestIds.idTypeTrigger));
      await tester.pumpAndSettle();
      await _selectOption(tester, "Driver's licence");
      expect(forms().idDetails.idType, UseSmileIDSampleIdType.driversLicense);

      await tester.tap(byId(UseSmileIDSampleTestIds.countryTrigger));
      await tester.pumpAndSettle();
      await _selectOption(tester, 'Ghana');

      expect(forms().idDetails.idType, isNull);
    });

    testWidgets('continue waits for all three', (WidgetTester tester) async {
      await openForm(tester);
      expect(
        continueEnabled(tester, UseSmileIDSampleTestIds.kycContinue),
        isFalse,
      );

      await tester.tap(byId(UseSmileIDSampleTestIds.countryTrigger));
      await tester.pumpAndSettle();
      await _selectOption(tester, 'Kenya');
      await tester.tap(byId(UseSmileIDSampleTestIds.idTypeTrigger));
      await tester.pumpAndSettle();
      await _selectOption(tester, 'Passport');
      expect(
        continueEnabled(tester, UseSmileIDSampleTestIds.kycContinue),
        isFalse,
        reason: 'the number is still blank',
      );

      await tester.enterText(
        byId(UseSmileIDSampleTestIds.idNumberInput),
        'A1234567',
      );
      await tester.pumpAndSettle();
      expect(
        continueEnabled(tester, UseSmileIDSampleTestIds.kycContinue),
        isTrue,
      );
    });
  });

  group('the pickers', () {
    testWidgets('the country search filters on the name, never the code', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.countryPicker('biometricKyc'),
      );
      expect(byId(UseSmileIDSampleTestIds.countrySheet), findsOne);

      await tester.enterText(byId(UseSmileIDSampleTestIds.countrySearch), 'ke');
      await tester.pumpAndSettle();

      expect(find.text('Kenya'), findsOne);
      expect(
        find.text('Nigeria'),
        findsNothing,
        reason: 'its code is NG, and codes are not searched',
      );
    });

    testWidgets('a search matching nothing says what it looked for', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.countryPicker('biometricKyc'),
      );
      await tester.enterText(
        byId(UseSmileIDSampleTestIds.countrySearch),
        'Atlantis',
      );
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.countryEmpty), findsOne);
      expect(find.text('No country matches “Atlantis”'), findsOne);
    });

    // A deep link can reach the ID-type picker with no country, which the twin allows too.
    testWidgets('the ID type picker with no country says there are none', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, UseSmileIDSampleRoutes.idTypePicker('biometricKyc'));

      expect(byId(UseSmileIDSampleTestIds.idTypeSheet), findsOne);
      expect(find.text('No ID type for this country'), findsOne);
    });

    // R12: the picker path is a layer over the form, so the form is behind the scrim rather than
    // a grey void.
    testWidgets('a picker link opens the form with the sheet over it', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        UseSmileIDSampleRoutes.countryPicker('biometricKyc'),
      );

      expect(byId(UseSmileIDSampleTestIds.kycFormScreen), findsOne);
      expect(byId(UseSmileIDSampleTestIds.countrySheet), findsOne);
    });
  });
}

/// Fills the three fields the default requirement asks for.
Future<void> _fillUserDetails(
  WidgetTester tester,
  Finder Function(String) byId,
) async {
  await tester.enterText(
    byId(UseSmileIDSampleTestIds.userDetailsField('firstName')),
    'Njeri',
  );
  await tester.enterText(
    byId(UseSmileIDSampleTestIds.userDetailsField('lastName')),
    'Wanjiku',
  );
  await tester.enterText(
    byId(UseSmileIDSampleTestIds.userDetailsField('email')),
    'njeri@example.com',
  );
  await tester.pumpAndSettle();
}

/// Taps one option row by its words, then lets the sheet close.
Future<void> _selectOption(WidgetTester tester, String label) async {
  tester
      .widgetList<UseSmileIDSampleOptionRow>(
        find.byType(UseSmileIDSampleOptionRow),
      )
      .firstWhere((UseSmileIDSampleOptionRow row) => row.label == label)
      .onTap();
  await tester.pumpAndSettle();
}
