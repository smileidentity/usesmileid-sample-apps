import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Edge to edge, a sheet's content must end above the navigation bar.
void main() {
  Future<void> hostSheet(WidgetTester tester, Widget sheet) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852)
      ..viewPadding = const FakeViewPadding(bottom: _navigationBar)
      ..padding = const FakeViewPadding(bottom: _navigationBar);
    addTearDown(tester.view.reset);
    // As njia hosts a sheet step: the panel at the bottom of the window, the host drawing the rest.
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Align(alignment: Alignment.bottomCenter, child: sheet),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the partial sheet ends its last row above the bar', (
    WidgetTester tester,
  ) async {
    await hostSheet(
      tester,
      const UseSmileIDSamplePartialSheetBody(child: Text(_lastRow)),
    );

    expect(
      tester.getRect(find.text(_lastRow)).bottom,
      lessThanOrEqualTo(852 - _navigationBar),
    );
  });

  testWidgets('the full-height sheet ends its list above the bar', (
    WidgetTester tester,
  ) async {
    await hostSheet(
      tester,
      SizedBox(
        height: 852,
        child: UseSmileIDSampleFullHeightSheetBody(
          title: 'Country',
          onClose: () {},
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: Text(_lastRow),
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.text(_lastRow)).bottom,
      lessThanOrEqualTo(852 - _navigationBar),
    );
  });
}

/// Three-button navigation, the tallest bar Android draws.
const double _navigationBar = 48;

const String _lastRow = 'last row';
