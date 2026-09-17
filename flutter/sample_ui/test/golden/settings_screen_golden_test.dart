import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// Every state `spec/screens.json` lists for settings, light and dark, plus the mutex's own copy.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('settings default', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_settings',
      _settings,
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  testWidgets('settings survives max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(
      tester,
      _settings(),
      // The screen owns its scroll view, and at 2x it needs far more than one host to lay out.
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
      // The row's title carries the mark, and the word is wider than the row's text column at 2x.
      // Same open question as the product cards: `ui-work-plan.md` §5 item 3a.
      knownOpenWords: const <String>{'SmartSelfie\u2122'},
    );
  });

  testWidgets('settings alt profile', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_settings_alt_profile',
      () => _settings(
        organisation: 'Zanzibar Microfinance',
        initials: 'ZM',
        avatarIndex: 1,
      ),
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  testWidgets('settings newly created profile', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_settings_new_profile',
      () => _settings(
        organisation: 'Default profile',
        initials: '',
        avatarIndex: 3,
      ),
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  /// Agent mode on, which is the state each CAPTURE row's supporting line changes for.
  testWidgets('settings agent mode', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_settings_agent_mode',
      () => _settings(
        settings: const UseSmileIDSampleSettings(
          enhancedSmartSelfie: false,
          agentMode: true,
        ),
      ),
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  /// The consent row's overridden line, which only a consent-binding token produces.
  testWidgets('settings consent bound by token', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_settings_consent_bound',
      () => _settings(consentBoundByToken: true),
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });
}

Widget _settings({
  UseSmileIDSampleSettings settings = const UseSmileIDSampleSettings(),
  String organisation = 'Kobo Bank',
  String initials = 'KB',
  int avatarIndex = 0,
  bool consentBoundByToken = false,
}) => UseSmileIDSampleSettingsScreen(
  state: UseSmileIDSampleSettingsState(
    settings: settings,
    organisation: organisation,
    initials: initials,
    versionLabel: 'Smile ID Sample App · 1.0.0',
    consentBoundByToken: consentBoundByToken,
    avatarColor: avatarColorForProfile(avatarIndex),
  ),
  onSettingChanged: _ignoreSetting,
  onProfileTap: () {},
  onNavRowTap: _ignoreRow,
  onSignOut: () {},
  // The DEBUG section is shown so the baseline records it; the host hides it on release.
  onOpenScenarioDrawer: () {},
);

void _ignoreSetting(UseSmileIDSampleSetting setting, bool enabled) {}

void _ignoreRow(UseSmileIDSampleNavRow row) {}
