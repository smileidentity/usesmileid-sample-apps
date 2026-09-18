import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'spec_file.dart';

/// Every state `spec/screens.json` lists is either goldened or exempted in writing.
void main() {
  late List<Map<String, Object?>> screens;

  setUpAll(() {
    screens = (spec('screens.json')['screens']! as List<Object?>)
        .cast<Map<String, Object?>>();
  });

  /// Whether both schemes of [name] are recorded.
  bool hasBaseline(String name) =>
      File('test/goldens/${name}_light.png').existsSync() &&
      File('test/goldens/${name}_dark.png').existsSync();

  test('every state this app owns is goldened or exempted, with a reason', () {
    final List<String> unaccounted = <String>[];
    for (final Map<String, Object?> screen in screens) {
      // The SDK draws its own screens; this app cannot golden what it does not render.
      if (screen['owner'] != 'sample') {
        continue;
      }
      final String id = screen['id']! as String;
      for (final Object? entry in screen['states']! as List<Object?>) {
        final String state =
            (entry! as Map<String, Object?>)['state']! as String;
        final String key = '$id.$state';
        final String? baseline = useSmileIDSampleGoldenFor[key];
        final String? exempt = useSmileIDSampleGoldenExempt[key];
        if (baseline == null && exempt == null) {
          unaccounted.add(key);
        } else if (baseline != null && !hasBaseline(baseline)) {
          unaccounted.add('$key -> $baseline (no such baseline)');
        }
      }
    }
    expect(
      unaccounted,
      isEmpty,
      reason:
          'add a baseline, or an exemption saying why the state is unreachable',
    );
  });

  test('no mapping or exemption names a state the spec does not list', () {
    final Set<String> declared = <String>{
      for (final Map<String, Object?> screen in screens)
        if (screen['owner'] == 'sample')
          for (final Object? entry in screen['states']! as List<Object?>)
            '${screen['id']}.${(entry! as Map<String, Object?>)['state']}',
    };
    expect(
      <String>{
        ...useSmileIDSampleGoldenFor.keys,
        ...useSmileIDSampleGoldenExempt.keys,
      }.difference(declared),
      isEmpty,
      reason: 'a stale entry claims coverage of a state that no longer exists',
    );
  });

  test('a state is exempted or goldened, never both', () {
    expect(
      useSmileIDSampleGoldenFor.keys.toSet().intersection(
        useSmileIDSampleGoldenExempt.keys.toSet(),
      ),
      isEmpty,
    );
  });
}

/// Which baseline covers each `spec/screens.json` state, by `screenId.state`.
const Map<String, String> useSmileIDSampleGoldenFor = <String, String>{
  'products.default': 'screen_products',
  'products.tokenLinked': 'screen_products_token_linked',
  'products.tokenLinkedLate': 'screen_products_token_linked_late',
  'products.tokenExpired': 'screen_products_token_expired',
  'profileSwitchSheet.default': 'sheet_profile_switch',
  'verifications.default': 'screen_verifications_seeded',
  'verifications.selectMode': 'screen_verifications_select_mode_empty',
  'verifications.itemsSelected': 'screen_verifications_select_mode',
  'verifications.afterDelete': 'screen_verifications_removal_notice',
  'verificationDetails.clear': 'screen_verification_details',
  'verificationDetails.attention': 'screen_verification_details_attention',
  'verificationDetails.blocked': 'screen_verification_details_blocked',
  'verificationDetails.processing': 'screen_verification_details_processing',
  'userDetails.empty': 'screen_user_details',
  'userDetails.editing': 'screen_user_details_editing',
  'userDetails.complete': 'screen_user_details_complete',
  'kycIdForm.empty': 'screen_kyc_form',
  'kycIdForm.selected': 'screen_kyc_form_complete',
  'countryPickerSheet.default': 'sheet_country_picker',
  'idTypePickerSheet.default': 'sheet_idtype_picker',
  'settings.default': 'screen_settings',
  'settings.altProfile': 'screen_settings_alt_profile',
  'settings.newlyCreatedProfile': 'screen_settings_new_profile',
  'profiles.default': 'screen_profiles',
  'profiles.created': 'screen_profiles_created',
  'profileConfig.activeProfile': 'screen_profile_config_active',
  'profileConfig.otherProfile': 'screen_profile_config',
  'profileConfig.newlyCreated': 'screen_profile_config_new',
  'newProfileSheet.empty': 'sheet_new_profile',
  'newProfileSheet.filled': 'sheet_new_profile_filled',
  'licenses.default': 'screen_licenses',
  'licenses.empty': 'screen_licenses_empty',
  'scenarioDrawer.flowScenarios': 'sheet_scenario_drawer',
  'scenarioDrawer.themeScenarios': 'sheet_scenario_drawer_themes',
};

/// States with no baseline, each with the reason it has none.
const Map<String, String> useSmileIDSampleGoldenExempt = <String, String>{
  'products.supersededListLayout':
      'Kept in the spec only so nobody re-implements it; the app never draws it.',
  'verifications.swipeToDelete':
      'The revealed backdrop is a component state, goldened as swipe_action; a '
      'screen-level capture mid-gesture is not reproducible in this harness.',
  'verifications.refreshing':
      'Pull-to-refresh on the LIST needs the status call, which needs a scanned '
      'session; the list has no refresh affordance yet.',
  'scanToken.default':
      'The scanner needs a camera and a token session, neither of which this app '
      'has; the screen is not built.',
  'scanToken.redirected':
      'Same screen, and the redirect is driven by a flow preflight that needs the SDK.',
};
