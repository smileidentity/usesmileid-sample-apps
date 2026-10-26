import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The Skip API submission switch: config.skipApiSubmission, off as the SDK defaults it.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: UseSmileIDSampleTheme.light(),
    home: Scaffold(body: child),
  );

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('the switch starts off and reports a toggle', (
    WidgetTester tester,
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
      byId(UseSmileIDSampleTestIds.settingSkipApiSubmission),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Centred: scrolled only until visible, the row can sit past the test viewport's edge.
    await Scrollable.ensureVisible(
      tester.element(byId(UseSmileIDSampleTestIds.settingSkipApiSubmission)),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Skip API submission'), findsOneWidget);
    expect(
      tester.getSemantics(
        byId(UseSmileIDSampleTestIds.settingSkipApiSubmission),
      ),
      isSemantics(isToggled: false),
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.settingSkipApiSubmission));
    expect(toggles, <(UseSmileIDSampleSetting, bool)>[
      (UseSmileIDSampleSetting.skipApiSubmission, true),
    ]);
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
}
