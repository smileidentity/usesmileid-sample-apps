import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import '../spec/spec_file.dart';

void main() {
  final UseSmileIDSampleResult running = UseSmileIDSampleResult.idle.started(
    scenario: UseSmileIDSampleScenario.normal,
    theme: UseSmileIDSampleThemeScenario.brandDefault,
    route: UseSmileIDSampleFlowRoute.fullscreen,
    environment: UseSmileIDSampleEnvironment.production,
  );

  group('the counts', () {
    test('start at zero for every run, not once per launch', () {
      final UseSmileIDSampleResult again = running
          .recorded(UseSmileIDSampleFlowStatus.cancelled)
          .refreshed()
          .started(
            scenario: UseSmileIDSampleScenario.normal,
            theme: UseSmileIDSampleThemeScenario.brandDefault,
            route: UseSmileIDSampleFlowRoute.fullscreen,
            environment: UseSmileIDSampleEnvironment.sandbox,
          );
      expect(again.resultCallbackCount, 0);
      expect(again.refreshCallbackCount, 0);
      expect(again.jobStatus, UseSmileIDSampleFlowStatus.running);
      expect(again.environment, UseSmileIDSampleEnvironment.sandbox);
    });

    test('count a second delivery rather than absorbing it', () {
      final UseSmileIDSampleResult twice = running
          .recorded(UseSmileIDSampleFlowStatus.succeeded, jobId: 'job-1')
          .recorded(UseSmileIDSampleFlowStatus.cancelled);
      expect(twice.resultCallbackCount, 2);
      expect(twice.jobStatus, UseSmileIDSampleFlowStatus.cancelled);
      expect(twice.jobId, isNull);
    });

    test('a refresh keeps the recorded job', () {
      final UseSmileIDSampleResult refreshed = running
          .recorded(
            UseSmileIDSampleFlowStatus.succeeded,
            jobId: 'job-1',
            userId: 'user-1',
          )
          .refreshed();
      expect(refreshed.refreshCallbackCount, 1);
      expect(refreshed.jobId, 'job-1');
      expect(refreshed.userId, 'user-1');
    });

    test('a run the gate blocked failed, but no callback fired', () {
      final UseSmileIDSampleResult blocked = UseSmileIDSampleResult.idle
          .blocked(
            'Missing partner icon',
            scenario: UseSmileIDSampleScenario.normal,
            theme: UseSmileIDSampleThemeScenario.brandDefault,
            route: UseSmileIDSampleFlowRoute.fullscreen,
            environment: UseSmileIDSampleEnvironment.sandbox,
          );
      expect(blocked.jobStatus, UseSmileIDSampleFlowStatus.failed);
      expect(blocked.resultCallbackCount, 0);
      expect(blocked.lastError, 'Missing partner icon');
    });

    test('the drawer moves an idle card and leaves a recorded run alone', () {
      final UseSmileIDSampleScenario other = UseSmileIDSampleScenario.values
          .firstWhere(
            (UseSmileIDSampleScenario it) =>
                it != UseSmileIDSampleScenario.normal,
          );
      expect(
        UseSmileIDSampleResult.idle
            .selecting(other, UseSmileIDSampleThemeScenario.brandDefault)
            .activeScenario,
        other,
      );
      expect(
        running
            .selecting(other, UseSmileIDSampleThemeScenario.brandDefault)
            .activeScenario,
        UseSmileIDSampleScenario.normal,
      );
    });
  });

  group('the tree', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    testWidgets('publishes every schema field under its spec id', (
      WidgetTester tester,
    ) async {
      final Map<String, Object?> properties =
          spec('result-card.schema.json')['properties']!
              as Map<String, Object?>;
      await pump(tester, UseSmileIDSampleResultCard(result: running));
      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.resultCard),
        findsOne,
      );
      for (final String field in properties.keys) {
        final String id =
            'sample_result_${field == 'resultCallbackCount'
                ? 'result_count'
                : field == 'refreshCallbackCount'
                ? 'refresh_count'
                : field.replaceAllMapped(RegExp('[A-Z]'), (Match m) => '_${m[0]!.toLowerCase()}')}';
        expect(find.bySemanticsIdentifier(id), findsOne, reason: field);
      }
    });

    testWidgets('an absent value renders as a dash, not as nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester, UseSmileIDSampleResultCard(result: running));
      expect(
        find.descendant(
          of: find.bySemanticsIdentifier(UseSmileIDSampleTestIds.resultJobId),
          matching: find.text('—'),
        ),
        findsOne,
      );
    });

    testWidgets('collapsing hides the fields and keeps the card', (
      WidgetTester tester,
    ) async {
      await pump(tester, UseSmileIDSampleResultCard(result: running));
      await tester.tap(find.text('Hide'));
      await tester.pump();
      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.resultJobStatus),
        findsNothing,
      );
      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.resultCard),
        findsOne,
      );
    });

    testWidgets('the compact line carries status, scenario and route only', (
      WidgetTester tester,
    ) async {
      await pump(tester, UseSmileIDSampleResultLine(result: running));
      for (final String id in <String>[
        UseSmileIDSampleTestIds.resultJobStatus,
        UseSmileIDSampleTestIds.resultActiveScenario,
        UseSmileIDSampleTestIds.resultRoute,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOne, reason: id);
      }
      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.resultEnvironment),
        findsNothing,
      );
    });
  });
}
