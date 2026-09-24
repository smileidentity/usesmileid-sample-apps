import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The two pre-flow forms and their two pickers, light and dark.
void main() {
  setUpAll(loadSampleFonts);

  /// A first run: no profile, so the organisation row shows and the header says so.
  testWidgets('user details empty', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_user_details',
      () => _userDetails(withProfile: false),
    );
  });

  /// The first run once typed: "Save as a new profile" is offered.
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

  /// Complete: the hint changes and "Save to" the profile appears, since the details differ from it.
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
      () => _kycForm(
        details: const UseSmileIDSampleIdDetails(
          country: UseSmileIDSampleCountry.ke,
          idType: UseSmileIDSampleIdType.nationalId,
          idNumber: 'A1234567',
        ),
      ),
    );
  });

  testWidgets('country picker', (WidgetTester tester) async {
    await _sheetGoldens(
      tester,
      'sheet_country_picker',
      () => UseSmileIDSampleCountryPickerSheet(
        selected: UseSmileIDSampleCountry.ke,
        onSelect: _ignoreCountry,
      ),
    );
  });

  /// No country chosen, which a deep link can reach and which has its own words.
  testWidgets('id type picker with no country', (WidgetTester tester) async {
    await _sheetGoldens(
      tester,
      'sheet_idtype_picker_empty',
      () => UseSmileIDSampleIdTypePickerSheet(
        country: null,
        selected: null,
        onSelect: _ignoreIdType,
      ),
    );
  });

  testWidgets('id type picker', (WidgetTester tester) async {
    await _sheetGoldens(
      tester,
      'sheet_idtype_picker',
      () => UseSmileIDSampleIdTypePickerSheet(
        country: UseSmileIDSampleCountry.ng,
        selected: UseSmileIDSampleIdType.passport,
        onSelect: _ignoreIdType,
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
}) => UseSmileIDSampleKycFormScreen(
  title: 'Biometric KYC',
  details: details,
  onBack: () {},
  onPickCountry: () {},
  onPickIdType: () {},
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

void _ignoreCountry(UseSmileIDSampleCountry country) {}

void _ignoreIdType(UseSmileIDSampleIdType idType) {}
