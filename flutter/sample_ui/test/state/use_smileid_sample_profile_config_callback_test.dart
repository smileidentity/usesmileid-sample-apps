import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, {String? override}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: UseSmileIDSampleTheme.light(),
          home: Scaffold(
            body: UseSmileIDSampleProfileConfigScreen(
              organisation: 'Kobo Bank',
              details: const UseSmileIDSampleUserDetails(),
              isActive: false,
              onBack: () {},
              onFieldChanged: (UseSmileIDSampleUserField _, String _) {},
              onSave: () {},
              callbackUrl: 'https://kobo.example/hooks',
              onCallbackUrlChanged: (String _) {},
              callbackOverride: override,
            ),
          ),
        ),
      );

  TextField row(WidgetTester tester) => tester.widget<TextField>(
    find.descendant(
      of: find.bySemanticsIdentifier(
        UseSmileIDSampleTestIds.profileConfigCallbackUrl,
      ),
      matching: find.byType(TextField),
    ),
  );

  testWidgets('shows the profile URL and edits it with no session', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    expect(row(tester).enabled, isTrue);
    expect(row(tester).controller!.text, 'https://kobo.example/hooks');
  });

  testWidgets('a live session empties the row, says why, and stops edits', (
    WidgetTester tester,
  ) async {
    await pump(tester, override: 'Set by the scanned token');
    expect(row(tester).enabled, isFalse);
    expect(row(tester).controller!.text, isEmpty);
    expect(find.text('Set by the scanned token'), findsOne);
  });
}
