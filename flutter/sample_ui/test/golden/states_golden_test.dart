import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The two surfaces the design does not draw: the scenario drawer and the notices screen.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('scenario drawer', (WidgetTester tester) async {
    await goldens(tester, 'sheet_scenario_drawer', _drawer);
  });

  /// The same drawer with a theme scenario chosen, which is the other state the spec lists.
  testWidgets('scenario drawer themes', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_scenario_drawer_themes',
      () => _drawer(theme: UseSmileIDSampleThemeScenario.clashingHost),
    );
  });

  testWidgets('licenses', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_licenses',
      _licenses,
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  /// An empty list is a packaging fault, so the screen says so rather than showing a blank page.
  testWidgets('licenses empty', (WidgetTester tester) async {
    await goldens(
      tester,
      'screen_licenses_empty',
      () => _licenses(licenses: const UseSmileIDSampleLicenses()),
      hostHeight: goldenScreenHeight,
      fillsHost: true,
    );
  });

  testWidgets('scenario drawer survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _drawer(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });

  testWidgets('licenses survives max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(
      tester,
      _licenses(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
    );
  });
}

Widget _drawer({
  UseSmileIDSampleScenario scenario = UseSmileIDSampleScenario.normal,
  UseSmileIDSampleThemeScenario theme =
      UseSmileIDSampleThemeScenario.brandDefault,
}) => UseSmileIDSampleScenarioDrawer(
  scenario: scenario,
  theme: theme,
  onScenarioSelected: _ignoreScenario,
  onThemeSelected: _ignoreTheme,
);

Widget _licenses({UseSmileIDSampleLicenses licenses = _sample}) =>
    UseSmileIDSampleLicensesScreen(licenses: licenses, onBack: () {});

/// A fixed three, so the baseline does not move with the dependency graph.
const UseSmileIDSampleLicenses _sample = UseSmileIDSampleLicenses(
  components: <UseSmileIDSampleNotice>[
    UseSmileIDSampleNotice(
      component: 'go_router',
      licenseId: 'BSD-3-Clause',
      licenseName: 'BSD 3-Clause License',
      text: 'Copyright 2013 The Flutter Authors. All rights reserved.',
    ),
    UseSmileIDSampleNotice(
      component: 'flutter_riverpod',
      licenseId: 'MIT',
      licenseName: 'MIT License',
      text: 'MIT License\n\nCopyright (c) 2020 Remi Rousselet',
    ),
    // No licenseName: the screen omits the subtitle rather than guessing at an unmatched licence.
    UseSmileIDSampleNotice(
      component: 'shared_preferences',
      text: 'Terms that match no known signature.',
    ),
  ],
);

void _ignoreScenario(UseSmileIDSampleScenario scenario) {}

void _ignoreTheme(UseSmileIDSampleThemeScenario theme) {}
