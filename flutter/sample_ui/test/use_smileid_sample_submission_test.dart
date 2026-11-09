import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The SUBMISSION section's switches: config.skipApiSubmission and config.allowOfflineMode, off as the SDK defaults them.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: UseSmileIDSampleTheme.light(),
    home: Scaffold(body: child),
  );

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  Future<List<(UseSmileIDSampleSetting, bool)>> toggleRow(
    WidgetTester tester,
    String id,
    String title,
  ) async {
    final List<(UseSmileIDSampleSetting, bool)> toggles =
        <(UseSmileIDSampleSetting, bool)>[];
    await tester.pumpWidget(
      host(
        UseSmileIDSampleSettingsScreen(
          state: const UseSmileIDSampleSettingsState(
            settings: UseSmileIDSampleSettings(),
            organisation: 'Organisation',
            initials: 'OR',
            versionLabel: 'Smile ID · 1.0.0',
            deviceDark: false,
          ),
          onSettingChanged: (UseSmileIDSampleSetting setting, bool enabled) =>
              toggles.add((setting, enabled)),
          onProfileTap: () {},
          onNavRowTap: (UseSmileIDSampleNavRow _) {},
          onSignOut: () {},
          onCaptureModeTap: () {},
          onAppearanceTap: () {},
          onLanguageTap: () {},
        ),
      ),
    );
    await tester.scrollUntilVisible(
      byId(id),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Centred: scrolled only until visible, the row can sit past the test viewport's edge.
    await Scrollable.ensureVisible(tester.element(byId(id)), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
    expect(tester.getSemantics(byId(id)), isSemantics(isToggled: false));

    await tester.tap(byId(id));
    return toggles;
  }

  testWidgets('the switch starts off and reports a toggle', (
    WidgetTester tester,
  ) async {
    expect(
      await toggleRow(
        tester,
        UseSmileIDSampleTestIds.settingSkipApiSubmission,
        'Skip API submission',
      ),
      <(UseSmileIDSampleSetting, bool)>[
        (UseSmileIDSampleSetting.skipApiSubmission, true),
      ],
    );
  });

  testWidgets('the offline mode switch starts off and reports a toggle', (
    WidgetTester tester,
  ) async {
    expect(
      await toggleRow(
        tester,
        UseSmileIDSampleTestIds.settingAllowOfflineMode,
        'Allow offline mode',
      ),
      <(UseSmileIDSampleSetting, bool)>[
        (UseSmileIDSampleSetting.allowOfflineMode, true),
      ],
    );
  });

  test('the SDK submits by default, and the switch moves no other row', () {
    const UseSmileIDSampleSettings defaults = UseSmileIDSampleSettings();
    expect(defaults.skipApiSubmission, isFalse);
    final UseSmileIDSampleSettings skipped = defaults.withSetting(
      UseSmileIDSampleSetting.skipApiSubmission,
      true,
    );
    expect(skipped.skipApiSubmission, isTrue);
    for (final UseSmileIDSampleSetting other
        in UseSmileIDSampleSetting.values) {
      if (other == UseSmileIDSampleSetting.skipApiSubmission) continue;
      expect(skipped[other], defaults[other], reason: '$other moved');
    }
  });

  test('offline mode is off by default, and its switch moves no other row', () {
    const UseSmileIDSampleSettings defaults = UseSmileIDSampleSettings();
    expect(defaults.allowOfflineMode, isFalse);
    final UseSmileIDSampleSettings offline = defaults.withSetting(
      UseSmileIDSampleSetting.allowOfflineMode,
      true,
    );
    expect(offline.allowOfflineMode, isTrue);
    for (final UseSmileIDSampleSetting other
        in UseSmileIDSampleSetting.values) {
      if (other == UseSmileIDSampleSetting.allowOfflineMode) continue;
      expect(offline[other], defaults[other], reason: '$other moved');
    }
  });
}
