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

  testWidgets('auth user id with no jobs', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_auth_user_id_no_jobs',
      () => _authUserId(userId: '', previous: const <String>[]),
    );
  });

  testWidgets('auth user id with previous ids', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_auth_user_id_previous',
      () => _authUserId(userId: '', previous: _previousUserIds),
    );
  });

  testWidgets('auth user id selected', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_auth_user_id_selected',
      () => _authUserId(
        userId: _previousUserIds.first,
        previous: _previousUserIds,
      ),
    );
  });

  testWidgets('auth user id typed', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_auth_user_id_typed',
      () => _authUserId(
        userId: 'user_01typedbyhand0000000000',
        previous: _previousUserIds,
      ),
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

  testWidgets('id details complete in arabic', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_kyc_form_complete_ar',
      () => rightToLeft(
        UseSmileIDSampleLanguage.ar,
        _kycForm(details: _selected),
      ),
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

  testWidgets('document form passport matched', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_document_form_passport_matched',
      () => _kycForm(
        details: _documentForm(
          (UseSmileIDSampleDocument it) => it.code == 'PASSPORT',
        ),
        family: UseSmileIDSampleCatalogueFamily.document,
        title: 'Document Verification',
      ),
    );
  });

  testWidgets('document form two-sided matched', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_document_form_two_sided_matched',
      () => _kycForm(
        details: _documentForm(
          (UseSmileIDSampleDocument it) => it.code == 'IDENTITY_CARD',
        ),
        family: UseSmileIDSampleCatalogueFamily.document,
        title: 'Document Verification',
      ),
    );
  });

  testWidgets('document form one-sided matched', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_document_form_one_sided_matched',
      () => _kycForm(
        details: _documentForm(
          (UseSmileIDSampleDocument it) => it.code == 'ALIEN_CARD',
        ),
        family: UseSmileIDSampleCatalogueFamily.document,
        title: 'Document Verification',
      ),
    );
  });

  testWidgets('document form preset chosen', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_document_form_preset_chosen',
      () => _kycForm(
        details: _documentForm(
          (UseSmileIDSampleDocument it) => it.code == 'IDENTITY_CARD',
        ).withCaptureAsOverride(UseSmileIDSampleCaptureAs.passport),
        family: UseSmileIDSampleCatalogueFamily.document,
        title: 'Document Verification',
      ),
    );
  });

  testWidgets('document form generic chosen', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_document_form_generic_chosen',
      () => _kycForm(
        details:
            _documentForm(
                  (UseSmileIDSampleDocument it) => it.code == 'PASSPORT',
                )
                .copyWith(
                  genericDocument: const UseSmileIDSampleGenericDocument(
                    displayName: 'Booklet',
                    orientation: UseSmileIDSampleDocumentOrientation.portrait,
                    aspectRatio: UseSmileIDSampleAspectRatio.booklet,
                  ),
                )
                .withCaptureAsOverride(
                  UseSmileIDSampleCaptureAs.genericDocument,
                ),
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

/// A Kenyan fixture row, with "Capture as" untouched.
UseSmileIDSampleIdDetails _documentForm(
  bool Function(UseSmileIDSampleDocument) row,
) => UseSmileIDSampleIdDetails(
  country: CatalogueFixtures.kenya,
  document: CatalogueFixtures.documents('KE').firstWhere(row),
);

/// The Green Book: a standalone sub-type row, which Match document captures as the Green Book preset.
final UseSmileIDSampleIdDetails _documentSelected = UseSmileIDSampleIdDetails(
  country: CatalogueFixtures.southAfrica,
  document: CatalogueFixtures.documents(
    'ZA',
  ).firstWhere((UseSmileIDSampleDocument it) => it.subType == 'green_book'),
);

const List<String> _previousUserIds = <String>[
  'user_01m4gahg4ceceatsw25mc5dd1h',
  'user_01r4l94gahg4ceceatsw25mc5d',
  'user_01r4l94gahg4ceceatsw25mc51',
];

Widget _authUserId({required String userId, required List<String> previous}) =>
    UseSmileIDSampleAuthUserIdScreen(
      userId: userId,
      previousUserIds: previous,
      onUserIdChanged: (_) {},
      onRegister: () {},
      onBack: () {},
      onContinue: () {},
    );
