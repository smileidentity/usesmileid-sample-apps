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

  testWidgets('a hidden select takes no keyboard focus', (
    WidgetTester tester,
  ) async {
    await show(tester, jobs: const <UseSmileIDSampleJob>[]);

    final Iterable<ExcludeFocus> guards = tester.widgetList<ExcludeFocus>(
      find.ancestor(
        of: find.text('Select'),
        matching: find.byType(ExcludeFocus),
      ),
    );
    expect(guards.any((ExcludeFocus guard) => guard.excluding), isTrue);
  });

  testWidgets('select fades in when the first rows land', (
    WidgetTester tester,
  ) async {
    await show(tester, jobs: const <UseSmileIDSampleJob>[]);
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Scaffold(
          body: UseSmileIDSampleVerificationsScreen(
            state: UseSmileIDSampleVerificationsState(
              jobs: jobs,
              nowMillis: now,
            ),
            onFilterChanged: (_) {},
            onSelectModeChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final double midway = tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Select'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(midway, greaterThan(0));
    expect(midway, lessThan(1));
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

  testWidgets(
    'the chip row keeps its scroll when the header scrolls away and back',
    (WidgetTester tester) async {
      await show(tester, jobs: jobs);
      tester.view.physicalSize = const Size(393, 480);
      await tester.pumpAndSettle();
      final Finder error = find.bySemanticsIdentifier(
        UseSmileIDSampleTestIds.filterChip(
          UseSmileIDSampleJobFilter.values.last.id,
        ),
      );
      await tester.ensureVisible(error);
      await tester.pumpAndSettle();
      final double scrolledTo = tester.getRect(error).left;

      final Finder list = find.byType(Scrollable).first;
      await tester.drag(list, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, 3000));
      await tester.pumpAndSettle();

      expect(tester.getRect(error).left, scrolledTo);
    },
  );
}
