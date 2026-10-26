import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The API submission row and its sheet: config.skipApiSubmission, picked like the capture mode.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: UseSmileIDSampleTheme.light(),
    home: Scaffold(body: child),
  );

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('the row names the choice and opens the sheet', (
    WidgetTester tester,
  ) async {
    bool opened = false;
    await tester.pumpWidget(
      host(
        UseSmileIDSampleSettingsScreen(
          state: const UseSmileIDSampleSettingsState(
            settings: UseSmileIDSampleSettings(
              submission: UseSmileIDSampleSubmission.skip,
            ),
            organisation: 'Organisation',
            initials: 'OR',
            versionLabel: 'Smile ID · 1.0.0',
            deviceDark: false,
          ),
          onSettingChanged: (UseSmileIDSampleSetting _, bool _) {},
          onProfileTap: () {},
          onNavRowTap: (UseSmileIDSampleNavRow _) {},
          onSignOut: () {},
          onCaptureModeTap: () {},
          onSubmissionTap: () => opened = true,
          onAppearanceTap: () {},
          onLanguageTap: () {},
        ),
      ),
    );
    await tester.scrollUntilVisible(
      byId(UseSmileIDSampleTestIds.settingSubmission),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Centred: scrolled only until visible, the row can sit past the test viewport's edge.
    await Scrollable.ensureVisible(
      tester.element(byId(UseSmileIDSampleTestIds.settingSubmission)),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Skip API submission'), findsOneWidget);

    await tester.tap(byId(UseSmileIDSampleTestIds.settingSubmission));
    expect(opened, isTrue);
  });

  testWidgets('the sheet checks the choice and reports a pick', (
    WidgetTester tester,
  ) async {
    final List<UseSmileIDSampleSubmission> picked =
        <UseSmileIDSampleSubmission>[];
    await tester.pumpWidget(
      host(
        UseSmileIDSampleSubmissionSheet(
          selected: UseSmileIDSampleSubmission.submit,
          onSelect: picked.add,
        ),
      ),
    );
    expect(find.text('Submit to Smile ID'), findsOneWidget);
    expect(
      tester.getSemantics(
        byId(UseSmileIDSampleTestIds.submissionOption('submit')),
      ),
      isSemantics(isSelected: true),
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.submissionOption('skip')));
    expect(picked, <UseSmileIDSampleSubmission>[
      UseSmileIDSampleSubmission.skip,
    ]);
  });

  test(
    "only skip turns on skipApiSubmission, and the SDK's default submits",
    () {
      expect(
        const UseSmileIDSampleSettings().submission,
        UseSmileIDSampleSubmission.submit,
      );
      expect(UseSmileIDSampleSubmission.submit.skipsApiSubmission, isFalse);
      expect(UseSmileIDSampleSubmission.skip.skipsApiSubmission, isTrue);
      expect(
        UseSmileIDSampleSubmission.values.map(
          (UseSmileIDSampleSubmission it) => it.id,
        ),
        <String>['submit', 'skip'],
      );
    },
  );
}
