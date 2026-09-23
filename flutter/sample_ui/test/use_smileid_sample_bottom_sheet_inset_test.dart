import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Edge to edge, a sheet's content must end above the navigation bar.
void main() {
  Future<void> openSheet(
    WidgetTester tester,
    Future<void> Function(BuildContext context) show,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852)
      ..viewPadding = const FakeViewPadding(bottom: _navigationBar)
      ..padding = const FakeViewPadding(bottom: _navigationBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the partial sheet ends its last row above the bar', (
    WidgetTester tester,
  ) async {
    await openSheet(
      tester,
      (BuildContext context) => showUseSmileIDSampleSheet<void>(
        context: context,
        builder: (_) => const Text(_lastRow),
      ),
    );

    expect(
      tester.getRect(find.text(_lastRow)).bottom,
      lessThanOrEqualTo(852 - _navigationBar),
    );
  });

  testWidgets('the full-height sheet ends its list above the bar', (
    WidgetTester tester,
  ) async {
    await openSheet(
      tester,
      (BuildContext context) => showUseSmileIDSampleFullHeightSheet<void>(
        context: context,
        title: 'Country',
        builder: (_) => const Align(
          alignment: Alignment.bottomCenter,
          child: Text(_lastRow),
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
