import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

void main() {
  for (final double scale in <double>[1, 2]) {
    testWidgets('the selected row draws its check at ${scale}x', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UseSmileIDSampleTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: UseSmileIDSampleProfileRow(
                organisation: 'Kobo Bank',
                supportingText: 'Ada Okafor',
                initials: 'AO',
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(UseSmileIDSampleIcon), findsOne);
    });
  }
}
