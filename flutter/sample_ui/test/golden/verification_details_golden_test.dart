import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The two states `spec/screens.json` lists for the detail page, light and dark.
///
/// Timestamps are built in UTC and rendered in UTC, so the baselines are identical in any zone —
/// the list's own goldens use local wall-clock components for the same reason.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('verification details', (WidgetTester tester) async {
    await _screenGoldens(tester, 'screen_verification_details', _details);
  });

  /// A job this build never stored, which a stale deep link lands on.
  testWidgets('verification details with nothing stored', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_verification_details_empty',
      () => _details(stored: false),
    );
  });

  /// A job that never reached the API has no transport outcome, so the status row is uncoloured.
  testWidgets('verification details never submitted', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_verification_details_unsubmitted',
      () => _details(job: _job(httpStatus: null, message: '')),
    );
  });

  /// A blocked job that the transport accepted: the badge is red and the status row is green.
  testWidgets('verification details blocked but accepted', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_verification_details_blocked',
      () => _details(
        job: _job(status: UseSmileIDSampleStatus.blocked, message: 'Rejected'),
      ),
    );
  });

  testWidgets('verification details attention', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verification_details_attention',
      () => _details(
        job: _job(
          status: UseSmileIDSampleStatus.attention,
          message: 'Provisional — needs review',
        ),
      ),
    );
  });

  /// Accepted but not decided: a 202 beside a Processing badge.
  testWidgets('verification details processing', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verification_details_processing',
      () => _details(
        job: _job(
          status: UseSmileIDSampleStatus.processing,
          message: 'Submitted, awaiting result',
          httpStatus: 202,
        ),
      ),
    );
  });

  testWidgets('verification details survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _details(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
      knownOpenWords: _openWords,
    );
  });
}

Future<void> _screenGoldens(
  WidgetTester tester,
  String name,
  Widget Function() build,
) => goldens(
  tester,
  name,
  build,
  hostHeight: goldenScreenHeight,
  fillsHost: true,
);

/// Every callback the tab passes is passed here too, or the picture shows fewer affordances than
/// the app renders — which is the divergence a component golden cannot catch on its own.
Widget _details({UseSmileIDSampleJob? job, bool stored = true}) {
  final UseSmileIDSampleJob? found = stored ? job ?? _job() : null;
  return UseSmileIDSampleVerificationDetailsScreen(
    jobId: found?.id ?? 'job_never_existed',
    job: found == null
        ? const UseSmileIDSampleJobLookup.none()
        : UseSmileIDSampleJobLookup.found(found),
    onBack: () {},
    onDelete: () {},
    onRefresh: () async {},
    onCopy: _ignoreCopy,
  );
}

UseSmileIDSampleJob _job({
  UseSmileIDSampleStatus status = UseSmileIDSampleStatus.clear,
  String message = 'Approved',
  int? httpStatus = 200,
}) => UseSmileIDSampleJob(
  id: 'job_00ky31za00',
  userId: 'user_00ky31za00',
  product: UseSmileIDSampleProduct.values.first,
  status: status,
  createdAtMillis: _createdAt,
  message: message,
  httpStatus: httpStatus,
);

/// A fixed instant in UTC, so the rendered timestamp is the same on any runner.
final int _createdAt = DateTime.utc(
  2026,
  7,
  16,
  13,
  3,
  41,
).millisecondsSinceEpoch;

void _ignoreCopy(String label, String value) {}

/// The words `ui-work-plan.md` §5 item 3a records as breaking at 2x.
const Set<String> _openWords = <String>{
  'SmartSelfie™',
  'Enrollment',
  'Verification',
};
