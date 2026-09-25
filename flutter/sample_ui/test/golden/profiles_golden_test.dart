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

  testWidgets('profiles list on a plain launch', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_profiles_starter',
      () => _list(profiles: const <UseSmileIDSampleProfile>[]),
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

  /// The list just after a profile was created: the confirmation carries the activate offer.
  testWidgets('profiles list after creating one', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_profiles_created',
      () => _list(createdNotice: 'Karibu Pay'),
    );
  });

  /// A profile created by the sheet, which is not active and keeps the name the sheet gave it.
  testWidgets('profile config newly created', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_profile_config_new',
      () => UseSmileIDSampleProfileConfigScreen(
        organisation: 'Karibu Pay',
        onDelete: () {},
        details: const UseSmileIDSampleUserDetails(
          firstName: 'Njeri',
          lastName: 'Wanjiku',
        ),
        isActive: false,
        onBack: () {},
        onFieldChanged: _ignoreField,
        onSave: () {},
      ),
    );
  });

  testWidgets('profile switch sheet', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_profile_switch',
      () => UseSmileIDSampleProfileSwitchSheet(
        profiles: UseSmileIDSampleProfiles.fixtures(),
        activeId: 'p-1',
        onSelect: _ignoreProfile,
        onCreate: () {},
      ),
    );
  });

  testWidgets('new profile sheet', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_new_profile',
      () => UseSmileIDSampleNewProfileSheet(onCreate: _ignoreCreate),
    );
  });

  /// The same sheet with its three required fields typed, so its confirm is live. It holds its own
  /// state, so the only way to pose it is to type into it.
  testWidgets('new profile sheet filled', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_new_profile_filled',
      () => UseSmileIDSampleNewProfileSheet(onCreate: _ignoreCreate),
      afterPump: (WidgetTester tester) async {
        for (final (String id, String value) in <(String, String)>[
          (UseSmileIDSampleTestIds.newProfileName, 'Karibu Pay'),
          (UseSmileIDSampleTestIds.newProfileFirstName, 'Njeri'),
          (UseSmileIDSampleTestIds.newProfileLastName, 'Wanjiku'),
        ]) {
          await tester.enterText(find.bySemanticsIdentifier(id), value);
        }
        await tester.pump();
      },
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
Widget _list({List<UseSmileIDSampleProfile>? profiles, String? createdNotice}) {
  final List<UseSmileIDSampleProfile> shown =
      profiles ?? UseSmileIDSampleProfiles.fixtures();
  return UseSmileIDSampleProfilesScreen(
    profiles: shown,
    activeId: shown.isEmpty ? null : shown.first.id,
    onBack: () {},
    onProfileTap: _ignoreProfile,
    onCreate: () {},
    createdNotice: createdNotice,
    onMakeCreatedActive: () {},
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
  onDelete: () {},
);

void _ignoreProfile(UseSmileIDSampleProfile profile) {}

void _ignoreField(UseSmileIDSampleUserField field, String value) {}

void _ignoreCreate(String organisation, UseSmileIDSampleUserDetails details) {}
