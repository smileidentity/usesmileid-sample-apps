import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The Theme row and its sheet, driven by the device's theme rather than the app's.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: UseSmileIDSampleTheme.light(),
    home: Scaffold(body: child),
  );

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('the row follows the device under System and opens the sheet', (
    WidgetTester tester,
  ) async {
    bool opened = false;
    Widget settings({required bool deviceDark}) => host(
      UseSmileIDSampleSettingsScreen(
        state: UseSmileIDSampleSettingsState(
          settings: const UseSmileIDSampleSettings(),
          organisation: 'Organisation',
          initials: 'OR',
          versionLabel: 'Smile ID · 1.0.0',
          deviceDark: deviceDark,
        ),
        onSettingChanged: (UseSmileIDSampleSetting _, bool _) {},
        onProfileTap: () {},
        onNavRowTap: (UseSmileIDSampleNavRow _) {},
        onSignOut: () {},
        onCaptureModeTap: () {},
        onAppearanceTap: () => opened = true,
        onLanguageTap: () {},
      ),
    );

    await tester.pumpWidget(settings(deviceDark: true));
    expect(find.text('System (Dark)'), findsOneWidget);

    await tester.pumpWidget(settings(deviceDark: false));
    expect(find.text('System (Light)'), findsOneWidget);

    await tester.tap(byId(UseSmileIDSampleTestIds.settingAppearance));
    expect(opened, isTrue);
  });

  testWidgets(
    'the sheet checks the choice, names the device on System, and reports a pick',
    (WidgetTester tester) async {
      final List<UseSmileIDSampleAppearance> picked =
          <UseSmileIDSampleAppearance>[];
      Widget sheet({required bool deviceDark}) => host(
        UseSmileIDSampleAppearanceSheet(
          selected: UseSmileIDSampleAppearance.light,
          deviceDark: deviceDark,
          onSelect: picked.add,
        ),
      );

      await tester.pumpWidget(sheet(deviceDark: true));
      expect(find.text('System (Dark)'), findsOneWidget);
      expect(
        tester.getSemantics(
          byId(UseSmileIDSampleTestIds.appearanceOption('light')),
        ),
        isSemantics(isSelected: true),
      );

      await tester.pumpWidget(sheet(deviceDark: false));
      expect(find.text('System (Light)'), findsOneWidget);

      await tester.tap(byId(UseSmileIDSampleTestIds.appearanceOption('dark')));
      expect(picked, <UseSmileIDSampleAppearance>[
        UseSmileIDSampleAppearance.dark,
      ]);
    },
  );
}
