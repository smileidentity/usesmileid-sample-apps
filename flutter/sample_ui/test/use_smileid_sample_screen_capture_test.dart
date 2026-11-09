import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The Allow screen capture switch: config.allowScreenCapture, on in the sample where the SDK defaults it off.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: UseSmileIDSampleTheme.light(),
    home: Scaffold(body: child),
  );

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('the switch starts on and reports a toggle', (
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
      byId(UseSmileIDSampleTestIds.settingAllowScreenCapture),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Centred: scrolled only until visible, the row can sit past the test viewport's edge.
    await Scrollable.ensureVisible(
      tester.element(byId(UseSmileIDSampleTestIds.settingAllowScreenCapture)),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Allow screen capture'), findsOneWidget);
    expect(
      tester.getSemantics(
        byId(UseSmileIDSampleTestIds.settingAllowScreenCapture),
      ),
      isSemantics(isToggled: true),
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.settingAllowScreenCapture));
    expect(toggles, <(UseSmileIDSampleSetting, bool)>[
      (UseSmileIDSampleSetting.allowScreenCapture, false),
    ]);
  });

  test(
    'the sample allows screen capture by default, and the switch moves no other row',
    () {
      const UseSmileIDSampleSettings defaults = UseSmileIDSampleSettings();
      expect(defaults.allowScreenCapture, isTrue);
      final UseSmileIDSampleSettings blocked = defaults.withSetting(
        UseSmileIDSampleSetting.allowScreenCapture,
        false,
      );
      expect(blocked.allowScreenCapture, isFalse);
      for (final UseSmileIDSampleSetting other
          in UseSmileIDSampleSetting.values) {
        if (other == UseSmileIDSampleSetting.allowScreenCapture) continue;
        expect(blocked[other], defaults[other], reason: '$other moved');
      }
    },
  );
}
