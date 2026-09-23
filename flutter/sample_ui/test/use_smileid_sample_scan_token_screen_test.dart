import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The scan screen's own failure paths, which no golden can reach.
void main() {
  testWidgets('a clipboard that throws reads as an empty one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Scaffold(
          body: UseSmileIDSampleScanTokenScreen(
            onBack: () {},
            onLink: (_) {},
            onSimulate: (_, _, _) {},
            onPaste: () async => throw StateError('clipboard unavailable'),
          ),
        ),
      ),
    );
    await tester.tap(
      find.bySemanticsIdentifier(UseSmileIDSampleTestIds.tokenPaste),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('The clipboard holds no text to paste.'), findsOne);
  });
}
