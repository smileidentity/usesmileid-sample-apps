import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden/golden_harness.dart';

/// The bar floats over the page and insets nothing, so each screen reserves its own room.
void main() {
  setUpAll(loadSampleFonts);

  for (final double width in <double>[_smallestPhone, goldenWidth]) {
    for (final double scale in <double>[1, 1.3, 1.5, 1.75, maxTextScale]) {
      testWidgets('the last row clears the bar at ${width}dp and scale $scale', (
        WidgetTester tester,
      ) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(width, _hostHeight)
          ..viewPadding = const FakeViewPadding(bottom: _gestureInset)
          ..padding = const FakeViewPadding(bottom: _gestureInset);
        addTearDown(tester.view.reset);

        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MediaQuery(
            // Copied onto the view's own data: a bare MediaQueryData zeroes the gesture inset on
            // both sides of the comparison, which is the value that makes any formula look right.
            data: MediaQueryData.fromView(
              tester.view,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(
              theme: UseSmileIDSampleTheme.light(),
              home: Scaffold(
                extendBody: true,
                bottomNavigationBar: UseSmileIDSampleNavBar(
                  // The longest label, which is the one that wraps and grows the bar.
                  selected: UseSmileIDSampleNavItem.verifications,
                  onSelect: _ignoreItem,
                  onTokenTap: () {},
                ),
                body: Builder(
                  builder: (BuildContext context) => ListView(
                    controller: controller,
                    padding: EdgeInsets.only(
                      bottom: useSmileIDSampleNavBarClearance(context),
                    ),
                    children: <Widget>[
                      for (int row = 0; row < _rows; row++)
                        SizedBox(
                          key: ValueKey<int>(row),
                          height: _rowHeight,
                          child: Text('row $row'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pump();

        final double lastRow = tester
            .getRect(find.byKey(const ValueKey<int>(_rows - 1)))
            .bottom;
        final double barTop = tester
            .getRect(find.byType(UseSmileIDSampleNavBar))
            .top;
        expect(
          lastRow,
          lessThanOrEqualTo(barTop),
          reason:
              'scrolled to the end, the last row ends at $lastRow with the bar starting at $barTop',
        );
      });
    }
  }
}

void _ignoreItem(UseSmileIDSampleNavItem item) {}

/// The narrowest phone either original supports: the iOS 15 floor's first-generation SE, and
/// Android's smallest phone bucket.
const double _smallestPhone = 320;

/// A gesture-navigation inset, so the bar's own bottom padding is not zero on both sides.
const double _gestureInset = 34;

/// Taller than the rows are, so there is something to scroll past the bar.
const double _hostHeight = 900;

const int _rows = 20;

const double _rowHeight = 80;
