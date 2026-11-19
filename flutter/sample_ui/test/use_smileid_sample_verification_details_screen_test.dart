import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The failure banner's taps and absences, which no golden can show.
void main() {
  UseSmileIDSampleJob job(UseSmileIDSampleStatus status) => UseSmileIDSampleJob(
    id: 'job_1',
    userId: 'user_1',
    product: UseSmileIDSampleProduct.biometricKyc,
    status: status,
    createdAtMillis: 0,
    message: 'Rejected',
    httpStatus: 200,
  );

  Future<void> details(
    WidgetTester tester, {
    UseSmileIDSampleJob? stored,
    UseSmileIDSampleErrorResolution? landedFailure,
    ValueChanged<UseSmileIDSampleErrorAction>? onErrorAction,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: UseSmileIDSampleTheme.light(),
      home: Scaffold(
        body: UseSmileIDSampleVerificationDetailsScreen(
          jobId: stored?.id ?? 'unsubmitted',
          job: stored == null
              ? const UseSmileIDSampleJobLookup.none()
              : UseSmileIDSampleJobLookup.found(stored),
          onBack: () {},
          landedFailure: landedFailure,
          onErrorAction: onErrorAction,
        ),
      ),
    ),
  );

  testWidgets(
    'a failed run states its message in place of missing and its button runs the action',
    (WidgetTester tester) async {
      final List<UseSmileIDSampleErrorAction> pressed =
          <UseSmileIDSampleErrorAction>[];
      await details(
        tester,
        landedFailure: UseSmileIDSampleErrorHandling.forStatus(503),
        onErrorAction: pressed.add,
      );

      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.detailsEmpty),
        findsNothing,
      );
      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.errorBanner),
        findsOne,
      );
      await tester.tap(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.errorAction),
      );
      expect(pressed, <UseSmileIDSampleErrorAction>[
        UseSmileIDSampleErrorAction.retry,
      ]);
    },
  );

  testWidgets(
    'a stored job that ended in error states why and leaves closing to the back button',
    (WidgetTester tester) async {
      await details(tester, stored: job(UseSmileIDSampleStatus.error));

      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.errorBanner),
        findsOne,
      );
      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.errorAction),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a stored job that passed states no failure even after a failed run',
    (WidgetTester tester) async {
      await details(
        tester,
        stored: job(UseSmileIDSampleStatus.clear),
        landedFailure: UseSmileIDSampleErrorHandling.forStatus(503),
      );

      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.errorBanner),
        findsNothing,
      );
    },
  );
}
