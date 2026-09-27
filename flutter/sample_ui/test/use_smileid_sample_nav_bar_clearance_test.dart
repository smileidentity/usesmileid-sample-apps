import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden/golden_harness.dart';

/// The bar floats over the page and insets nothing, so each screen reserves its own room.
void main() {
  setUpAll(loadSampleTextFonts);

  // Every tab: the selected item's label is what wraps and grows the bar, so each one sets its own height.
  for (final UseSmileIDSampleNavItem tab in UseSmileIDSampleNavItem.values) {
    for (final double width in <double>[smallestPhoneWidth, goldenWidth]) {
      for (final double scale in <double>[1, 1.3, 1.5, 1.75, maxTextScale]) {
        testWidgets(
          'the last row clears the bar on ${tab.name} at ${width}dp and scale $scale',
          (WidgetTester tester) async {
            tester.view
              ..devicePixelRatio = 1
              ..physicalSize = Size(width, _hostHeight)
              ..viewPadding = const FakeViewPadding(bottom: gestureInset)
              ..padding = const FakeViewPadding(bottom: gestureInset);
            addTearDown(tester.view.reset);

            final ScrollController controller = ScrollController();
            addTearDown(controller.dispose);

            await tester.pumpWidget(
              MediaQuery(
                // Copied onto the view's data: a bare MediaQueryData zeroes the inset on both sides.
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: MaterialApp(
                  theme: UseSmileIDSampleTheme.light(),
                  home: Scaffold(
                    extendBody: true,
                    bottomNavigationBar: UseSmileIDSampleNavBar(
                      selected: tab,
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
          },
        );
      }
    }
  }
}

void _ignoreItem(UseSmileIDSampleNavItem item) {}

/// Shorter than the rows stacked, so the list has somewhere to scroll.
const double _hostHeight = 900;

/// Enough of them, at [_rowHeight] each, to outrun the host so the end is reachable.
const int _rows = 20;

const double _rowHeight = 80;
