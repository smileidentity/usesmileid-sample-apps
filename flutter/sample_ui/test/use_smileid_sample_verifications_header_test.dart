import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The Verifications header: Select only when there is something to select, and every filter chip on one row.
void main() {
  const int now = 1784202612000;
  final List<UseSmileIDSampleJob> jobs = useSmileIDSampleJobFixtures(now);

  Future<void> show(
    WidgetTester tester, {
    required List<UseSmileIDSampleJob>? jobs,
    bool selectMode = false,
  }) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Scaffold(
          body: UseSmileIDSampleVerificationsScreen(
            state: UseSmileIDSampleVerificationsState(
              jobs: jobs,
              nowMillis: now,
              selectMode: selectMode,
            ),
            onFilterChanged: (_) {},
            onSelectModeChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder selectToggle() =>
      find.bySemanticsIdentifier(UseSmileIDSampleTestIds.selectToggle);

  double titleTop(WidgetTester tester) =>
      tester.getRect(find.text('Verifications')).top;

  testWidgets('an empty list offers nothing to select', (
    WidgetTester tester,
  ) async {
    await show(tester, jobs: const <UseSmileIDSampleJob>[]);

    expect(selectToggle(), findsNothing);
  });

  testWidgets('a list still loading offers nothing to select', (
    WidgetTester tester,
  ) async {
    await show(tester, jobs: null);

    expect(selectToggle(), findsNothing);
  });

  testWidgets('a list with rows offers select', (WidgetTester tester) async {
    await show(tester, jobs: jobs);

    expect(selectToggle(), findsOneWidget);
  });

  testWidgets('select mode keeps cancel even once the list empties', (
    WidgetTester tester,
  ) async {
    await show(tester, jobs: const <UseSmileIDSampleJob>[], selectMode: true);

    expect(selectToggle(), findsOneWidget);
  });

  testWidgets('the title stays put when select is hidden', (
    WidgetTester tester,
  ) async {
    await show(tester, jobs: jobs);
    final double withRows = titleTop(tester);

    await show(tester, jobs: const <UseSmileIDSampleJob>[]);

    expect(titleTop(tester), withRows);
  });

  testWidgets('every filter chip sits on one row', (WidgetTester tester) async {
    await show(tester, jobs: jobs);

    final Set<double> tops = <double>{
      for (final UseSmileIDSampleJobFilter chip
          in UseSmileIDSampleJobFilter.values)
        tester
            .getRect(
              find.bySemanticsIdentifier(
                UseSmileIDSampleTestIds.filterChip(chip.id),
              ),
            )
            .top,
    };
    expect(tops, hasLength(1));
  });
}
