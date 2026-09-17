import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The four profile surfaces `spec/screens.json` lists, light and dark.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('profiles list', (WidgetTester tester) async {
    await _screenGoldens(tester, 'screen_profiles', _list);
  });

  /// A plain launch: one starter with no person, so the caption is the placeholder.
  testWidgets('profiles list on a plain launch', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_profiles_starter',
      () => _list(profiles: UseSmileIDSampleProfiles.starter()),
    );
  });

  testWidgets('profile config', (WidgetTester tester) async {
    await _screenGoldens(tester, 'screen_profile_config', _config);
  });

  /// The active profile, where the page's only write is disabled.
  testWidgets('profile config already active', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_profile_config_active',
      () => _config(isActive: true),
    );
  });

  testWidgets('profiles list survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _list(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });

  testWidgets('profile config survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _config(),
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

/// Every callback the tab passes is passed here too, so the picture shows what the app renders.
Widget _list({List<UseSmileIDSampleProfile>? profiles}) {
  final List<UseSmileIDSampleProfile> shown =
      profiles ?? UseSmileIDSampleProfiles.fixtures();
  return UseSmileIDSampleProfilesScreen(
    profiles: shown,
    activeId: shown.first.id,
    onBack: () {},
    onProfileTap: _ignoreProfile,
    onCreate: () {},
  );
}

Widget _config({bool isActive = false}) => UseSmileIDSampleProfileConfigScreen(
  organisation: 'Kazi Microlending',
  details: const UseSmileIDSampleUserDetails(
    firstName: 'Amina',
    lastName: 'Diallo',
    email: 'amina@kazi.example',
  ),
  isActive: isActive,
  onBack: () {},
  onFieldChanged: _ignoreField,
  onSave: () {},
);

void _ignoreProfile(UseSmileIDSampleProfile profile) {}

void _ignoreField(UseSmileIDSampleUserField field, String value) {}
