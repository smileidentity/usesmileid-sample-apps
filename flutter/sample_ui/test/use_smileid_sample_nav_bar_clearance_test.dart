import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden/golden_harness.dart';

/// The bar floats over the page and insets nothing, so each screen reserves its own room.
void main() {
  for (final double scale in <double>[1, 1.3, 1.5, 1.75, maxTextScale]) {
    testWidgets('the reserved clearance covers the bar at text scale $scale', (
      WidgetTester tester,
    ) async {
      late double clearance;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            theme: UseSmileIDSampleTheme.light(),
            home: Builder(
              builder: (BuildContext context) {
                clearance = useSmileIDSampleNavBarClearance(context);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: UseSmileIDSampleNavBar(
                    selected: UseSmileIDSampleNavItem.products,
                    onSelect: (UseSmileIDSampleNavItem item) {},
                    onTokenTap: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      final double barHeight = tester
          .getSize(find.byType(UseSmileIDSampleNavBar))
          .height;
      expect(
        clearance,
        greaterThanOrEqualTo(barHeight),
        reason:
            'a screen reserving $clearance leaves its last row under a bar $barHeight tall',
      );
    });
  }
}
