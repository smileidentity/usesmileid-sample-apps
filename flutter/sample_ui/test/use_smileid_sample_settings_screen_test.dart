import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The Settings switch rows: the whole row is the control, as on the other three apps and for a screen reader.
void main() {
  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets(
    'a tap anywhere on a switch row flips that setting, which still reads as a switch',
    (WidgetTester tester) async {
      final List<(UseSmileIDSampleSetting, bool)> changed =
          <(UseSmileIDSampleSetting, bool)>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: UseSmileIDSampleTheme.light(),
          home: Scaffold(
            body: UseSmileIDSampleSettingsScreen(
              state: const UseSmileIDSampleSettingsState(
                settings: UseSmileIDSampleSettings(),
                organisation: 'Organisation',
                initials: 'OR',
                versionLabel: 'Smile ID · 1.0.0',
                deviceDark: false,
              ),
              onSettingChanged:
                  (UseSmileIDSampleSetting setting, bool enabled) =>
                      changed.add((setting, enabled)),
              onProfileTap: () {},
              onNavRowTap: (UseSmileIDSampleNavRow _) {},
              onSignOut: () {},
              onCaptureModeTap: () {},
              onAppearanceTap: () {},
              onLanguageTap: () {},
            ),
          ),
        ),
      );

      final Finder row = byId(UseSmileIDSampleTestIds.settingConsentStep);
      await tester.ensureVisible(row);
      expect(
        tester.getSemantics(row),
        isSemantics(hasToggledState: true, isToggled: true, isButton: false),
      );
      await tester.tapAt(tester.getTopLeft(row) + const Offset(120, 24));

      expect(changed, <(UseSmileIDSampleSetting, bool)>[
        (UseSmileIDSampleSetting.consentStep, false),
      ]);
    },
  );
}
