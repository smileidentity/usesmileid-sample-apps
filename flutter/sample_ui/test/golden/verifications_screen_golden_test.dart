import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The four states `spec/screens.json` lists for verifications, light and dark.
///
/// Every timestamp is built from LOCAL wall-clock components and rendered back to local ones, so
/// the day headers and the times are identical in any timezone. Absolute millis would not be: this
/// lane runs on a CI runner whose zone is not the author's, and the headers would move with it.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('verifications empty', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verifications_empty',
      () => _verifications(jobs: const <UseSmileIDSampleJob>[]),
    );
  });

  testWidgets('verifications seeded', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verifications_seeded',
      () => _verifications(jobs: _jobs),
    );
  });

  testWidgets('verifications filtered', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verifications_filtered',
      () => _verifications(
        jobs: _jobs,
        filter: UseSmileIDSampleJobFilter.blocked,
      ),
    );
  });

  /// A filter with NO match, which is a different empty text and keeps the chips switchable.
  testWidgets('verifications filtered to nothing', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verifications_filtered_empty',
      () => _verifications(
        jobs: _jobs
            .where(
              (UseSmileIDSampleJob job) =>
                  job.status != UseSmileIDSampleStatus.blocked,
            )
            .toList(),
        filter: UseSmileIDSampleJobFilter.blocked,
      ),
    );
  });

  /// Not an empty list: the store has not answered, so NEITHER empty state may draw.
  testWidgets('verifications before the store answers', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_verifications_loading',
      () => _verifications(jobs: null),
    );
  });

  testWidgets('verifications survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _verifications(jobs: _jobs),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
      // Every product word is wider than the row's text column at 2x, the same open design
      // question the products grid records.
      knownOpenWords: _rowOpenWords,
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

Widget _verifications({
  required List<UseSmileIDSampleJob>? jobs,
  UseSmileIDSampleJobFilter filter = UseSmileIDSampleJobFilter.all,
}) => UseSmileIDSampleVerificationsScreen(
  state: UseSmileIDSampleVerificationsState(
    jobs: jobs,
    nowMillis: _now,
    filter: filter,
  ),
  onFilterChanged: _ignoreFilter,
  onJobTap: _ignoreJob,
);

/// A fixed afternoon, so TODAY, YESTERDAY and a dated header are all on screen at once.
final int _now = DateTime(2026, 7, 16, 18, 30).millisecondsSinceEpoch;

/// Six rows across three days, which is every header form without filling the whole host.
final List<UseSmileIDSampleJob> _jobs = <UseSmileIDSampleJob>[
  _job(0, UseSmileIDSampleStatus.clear, DateTime(2026, 7, 16, 13, 3, 41)),
  _job(1, UseSmileIDSampleStatus.processing, DateTime(2026, 7, 16, 9, 12, 5)),
  _job(2, UseSmileIDSampleStatus.attention, DateTime(2026, 7, 15, 17, 45, 20)),
  _job(3, UseSmileIDSampleStatus.blocked, DateTime(2026, 7, 15, 8, 2, 9)),
  _job(4, UseSmileIDSampleStatus.clear, DateTime(2026, 7, 14, 22, 18, 55)),
  _job(5, UseSmileIDSampleStatus.clear, DateTime(2026, 7, 14, 11, 30, 0)),
];

UseSmileIDSampleJob _job(int i, UseSmileIDSampleStatus status, DateTime at) =>
    UseSmileIDSampleJob(
      id: 'job_${i.toString().padLeft(2, '0')}ky31za',
      userId: 'user_${i.toString().padLeft(2, '0')}ky31za',
      product: UseSmileIDSampleProduct.values[i % 6],
      status: status,
      createdAtMillis: at.millisecondsSinceEpoch,
    );

void _ignoreFilter(UseSmileIDSampleJobFilter filter) {}

void _ignoreJob(UseSmileIDSampleJob job) {}

/// The words `ui-work-plan.md` §5 item 3a records as breaking at 2x.
const Set<String> _rowOpenWords = <String>{
  'Enrollment',
  'Authentication',
  'Verification',
  'Document',
  'Enhanced',
  'Biometric',
  'SmartSelfie™',
};
