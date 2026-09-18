import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The four states `spec/screens.json` lists for verifications, light and dark.
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

  testWidgets('verifications in select mode', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verifications_select_mode',
      () => _verifications(
        jobs: _jobs,
        selectMode: true,
        selected: <String>{_jobs[1].id, _jobs[2].id},
      ),
    );
  });

  /// Select mode with nothing picked, which is the hint the bar shows rather than the count.
  testWidgets('verifications in select mode with nothing picked', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_verifications_select_mode_empty',
      () => _verifications(jobs: _jobs, selectMode: true),
    );
  });

  testWidgets('verifications after a removal', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_verifications_removal_notice',
      () => _verifications(jobs: _jobs.sublist(1), removedCount: 1),
    );
  });

  testWidgets('verifications after removing several', (
    WidgetTester tester,
  ) async {
    await _screenGoldens(
      tester,
      'screen_verifications_removal_notice_many',
      () => _verifications(jobs: _jobs.sublist(2), removedCount: 2),
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

/// Every callback the tab passes is passed here too: omitting one hides the affordance it drives,
/// and a baseline of a screen with fewer affordances than the app renders is the wrong picture.
Widget _verifications({
  required List<UseSmileIDSampleJob>? jobs,
  UseSmileIDSampleJobFilter filter = UseSmileIDSampleJobFilter.all,
  bool selectMode = false,
  Set<String> selected = const <String>{},
  int? removedCount,
}) => UseSmileIDSampleVerificationsScreen(
  state: UseSmileIDSampleVerificationsState(
    jobs: jobs,
    nowMillis: _now,
    filter: filter,
    selectMode: selectMode,
    selected: selected,
    removedCount: removedCount,
  ),
  onFilterChanged: _ignoreFilter,
  onJobTap: _ignoreJob,
  onSelectModeChanged: _ignoreFlag,
  onSelectionChanged: _ignoreSelection,
  onRemove: _ignoreIds,
  onUndo: () {},
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

void _ignoreFlag(bool on) {}

void _ignoreSelection(String jobId, bool selected) {}

void _ignoreIds(Set<String> ids) {}

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
