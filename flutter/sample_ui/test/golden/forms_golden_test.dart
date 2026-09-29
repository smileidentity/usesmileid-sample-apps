import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import '../support/catalogue_fixtures.dart';
import 'golden_harness.dart';

/// The two pre-flow forms and their pickers' ready states, light and dark.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('user details empty', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details',
      () => _userDetails(withProfile: false),
    );
  });

  testWidgets('user details with no profile', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details_no_profile',
      () => _userDetails(
        details: _filled,
        withProfile: false,
        organisation: 'Sahara Pay',
      ),
    );
  });

  testWidgets('user details with no profile survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _userDetails(
        details: _filled,
        withProfile: false,
        organisation: 'Sahara Pay',
      ),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });

  testWidgets('user details complete', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details_complete',
      () => _userDetails(details: _filled),
    );
  });

  /// What a token-bound contact does to the labels, reachable by constructing the requirement.
  testWidgets('user details with contact covered', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details_contact_covered',
      () => _userDetails(
        requirement: const UseSmileIDSampleUserDetailsRequirement(
          contact: false,
        ),
      ),
    );
  });

  /// Both names bound by a token.
  testWidgets('user details with names bound', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details_names_bound',
      () => _userDetails(
        requirement: const UseSmileIDSampleUserDetailsRequirement(
          firstName: false,
          lastName: false,
        ),
      ),
    );
  });

  /// Part-typed: what the form looks like while it is being filled in.
  testWidgets('user details editing', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details_editing',
      () => _userDetails(
        details: const UseSmileIDSampleUserDetails(firstName: 'Njeri'),
      ),
    );
  });

  testWidgets('id details empty', (WidgetTester tester) async {
    await _screenGoldens(tester, 'screen_kyc_form', _kycForm);
  });

  testWidgets('id details complete', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_kyc_form_complete',
      () => _kycForm(details: _selected),
    );
  });

  testWidgets('id details with a number outside the format', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_kyc_form_id_number_invalid',
      () => _kycForm(details: _selected.copyWith(idNumber: 'AO12345678')),
    );
  });

  testWidgets(
    'id details with a number outside the format survives max text scale',
    (WidgetTester tester) async {
      await assertSurvivesMaxTextScale(
        tester,
        _kycForm(details: _selected.copyWith(idNumber: 'AO12345678')),
        ownsScrolling: true,
        hostHeight: goldenScreenHeight * 2,
      );
    },
  );

  /// The country's list is still arriving: the trigger stays enabled and says so.
  testWidgets('id details while the list loads', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_kyc_form_loading',
      () => _kycForm(details: _countryOnly, loading: true),
    );
  });

  /// The list failed: the trigger goes back to its prompt, so the form never looks stuck.
  testWidgets('id details after the list failed', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_kyc_form_catalogue_error',
      () => _kycForm(details: _countryOnly),
    );
  });

  testWidgets('document form selected', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_document_form_selected',
      () => _kycForm(
        details: _documentSelected,
        family: UseSmileIDSampleCatalogueFamily.document,
        title: 'Document Verification',
      ),
    );
  });

  testWidgets('document form survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _kycForm(
        details: _documentSelected,
        family: UseSmileIDSampleCatalogueFamily.document,
        title: 'Document Verification',
      ),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });

  testWidgets('country picker', (WidgetTester tester) async {
    await _sheetGoldens(
      tester,
      'sheet_country_picker',
      () => UseSmileIDSampleCountryPickerSheet(
        catalogue: UseSmileIDSampleCatalogueReady<UseSmileIDSampleCountry>(
          CatalogueFixtures.countries(UseSmileIDSampleCatalogueFamily.kyc),
        ),
        selected: CatalogueFixtures.kenya,
        onSelect: (UseSmileIDSampleCountry _) {},
        onRetry: () {},
      ),
    );
  });

  testWidgets('id type picker', (WidgetTester tester) async {
    await _sheetGoldens(
      tester,
      'sheet_idtype_picker',
      () => UseSmileIDSampleIdTypePickerSheet(
        country: CatalogueFixtures.kenya,
        catalogue: UseSmileIDSampleCatalogueReady<UseSmileIDSampleKycIdType>(
          CatalogueFixtures.idTypes('KE'),
        ),
        selected: null,
        onSelect: (UseSmileIDSampleKycIdType _) {},
        onRetry: () {},
      ),
    );
  });

  testWidgets('user details survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _userDetails(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });

  testWidgets('id details survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _kycForm(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });
}

Future<void> _screenGoldens(
  WidgetTester tester,
  String name,
  Widget Function() build,
) => goldens(
  tester,
  name,
  build,
  hostHeight: goldenScreenHeight,
  fillsHost: true,
);

Future<void> _sheetGoldens(
  WidgetTester tester,
  String name,
  Widget Function() build,
) => goldens(tester, name, build);

Widget _userDetails({
  UseSmileIDSampleUserDetails details = const UseSmileIDSampleUserDetails(),
  UseSmileIDSampleUserDetailsRequirement requirement =
      const UseSmileIDSampleUserDetailsRequirement(),
  bool withProfile = true,
  String organisation = '',
}) => UseSmileIDSampleUserDetailsScreen(
  title: 'Biometric KYC',
  details: details,
  onBack: () {},
  onFieldChanged: _ignoreUserField,
  onContinue: () {},
  requirement: requirement,
  profile: withProfile ? UseSmileIDSampleProfiles.fixtures().first : null,
  onProfileTap: () {},
  onSaveToProfileChanged: _ignoreFlag,
  organisation: organisation,
  onOrganisationChanged: (String _) {},
);

Widget _kycForm({
  UseSmileIDSampleIdDetails details = const UseSmileIDSampleIdDetails(),
  UseSmileIDSampleCatalogueFamily family = UseSmileIDSampleCatalogueFamily.kyc,
  String title = 'Biometric KYC',
  bool loading = false,
}) => UseSmileIDSampleKycFormScreen(
  title: title,
  family: family,
  details: details,
  countryListLoading: loading,
  onBack: () {},
  onPickCountry: () {},
  onPickIdType: () {},
  onPickDocument: () {},
  onPickCaptureAs: () {},
  onIdNumberChanged: _ignoreText,
  onContinue: () {},
);

const UseSmileIDSampleUserDetails _filled = UseSmileIDSampleUserDetails(
  firstName: 'Njeri',
  lastName: 'Wanjiku',
  email: 'njeri@example.com',
);

void _ignoreUserField(UseSmileIDSampleUserField field, String value) {}

void _ignoreText(String value) {}

void _ignoreFlag(bool on) {}

/// A country chosen and nothing else, which is the only state that unlocks the second trigger.
const UseSmileIDSampleIdDetails _countryOnly = UseSmileIDSampleIdDetails(
  country: CatalogueFixtures.kenya,
);

final UseSmileIDSampleIdDetails _selected = UseSmileIDSampleIdDetails(
  country: CatalogueFixtures.kenya,
  idType: CatalogueFixtures.idTypes(
    'KE',
  ).firstWhere((UseSmileIDSampleKycIdType it) => it.type == 'NATIONAL_ID'),
  idNumber: '12345678',
);

/// The Green Book: a standalone sub-type row, captured as the API describes it.
final UseSmileIDSampleIdDetails _documentSelected = UseSmileIDSampleIdDetails(
  country: CatalogueFixtures.southAfrica,
  document: CatalogueFixtures.documents(
    'ZA',
  ).firstWhere((UseSmileIDSampleDocument it) => it.subType == 'green_book'),
);
