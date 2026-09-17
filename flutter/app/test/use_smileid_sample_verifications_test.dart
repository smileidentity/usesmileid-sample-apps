import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The verifications tab: what a launch shows, and what only `seedJobs` reaches.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> pumpTab(
    WidgetTester tester, {
    UseSmileIDSampleLaunchArgs args = const UseSmileIDSampleLaunchArgs(),
    UseSmileIDSampleJobsRepository? jobs,
  }) async {
    // The app's own start-up act, run here for the same reason the app runs it: seeding happens
    // once before the first frame, not inside the provider the screen watches.
    if (jobs != null) {
      await useSmileIDSampleApplyLaunch(args, jobs);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleLaunchArgsProvider.overrideWithValue(args),
          if (jobs != null)
            useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(
            initialLocation: UseSmileIDSampleRoutes.verifications,
          ),
        ),
      ),
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('a launch with no arguments stores nothing to show', (
    WidgetTester tester,
  ) async {
    await pumpTab(tester);
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.verificationsEmpty), findsOne);
    expect(find.text('No verifications yet'), findsOne);
    expect(byId(UseSmileIDSampleTestIds.jobRow(0)), findsNothing);
  });

  // The third state, which an empty list cannot express: before the store answers, the screen must claim nothing.
  testWidgets('before the store answers it claims nothing either way', (
    WidgetTester tester,
  ) async {
    final _HeldJobsRepository held = _HeldJobsRepository();
    await pumpTab(tester, jobs: held);
    await tester.pump();

    expect(byId(UseSmileIDSampleTestIds.verificationsEmpty), findsNothing);
    expect(find.text('No verifications yet'), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.filterChip('all')), findsOne);

    held.answer(const <UseSmileIDSampleJob>[]);
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.verificationsEmpty), findsOne);
  });

  testWidgets('seedJobs is the only way to the design eleven', (
    WidgetTester tester,
  ) async {
    await pumpTab(
      tester,
      args: const UseSmileIDSampleLaunchArgs(seedJobs: true),
      jobs: UseSmileIDSampleMemoryJobsRepository(),
    );
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.verificationsEmpty), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.jobRow(0)), findsOne);
    // The eleventh is below the fold in this window, so it has to be scrolled to rather than
    // looked for: a lazy list has not built a row nobody has come near.
    await tester.scrollUntilVisible(
      byId(UseSmileIDSampleTestIds.jobRow(10)),
      300,
    );
    expect(byId(UseSmileIDSampleTestIds.jobRow(10)), findsOne);
  });

  testWidgets('a chip narrows the list and the counts stay whole-list', (
    WidgetTester tester,
  ) async {
    await pumpTab(
      tester,
      args: const UseSmileIDSampleLaunchArgs(seedJobs: true),
      jobs: UseSmileIDSampleMemoryJobsRepository(),
    );
    await tester.pumpAndSettle();

    String countText(String filterId) => tester
        .widget<Text>(
          find.descendant(
            of: byId(UseSmileIDSampleTestIds.filterCount(filterId)),
            matching: find.byType(Text),
          ),
        )
        .data!;

    expect(countText('all'), '11');
    expect(countText('clear'), '6');

    await tester.tap(byId(UseSmileIDSampleTestIds.filterChip('blocked')));
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.jobRow(1)), findsOne);
    expect(byId(UseSmileIDSampleTestIds.jobRow(2)), findsNothing);
    expect(countText('all'), '11', reason: 'the counts do not follow the chip');
    expect(countText('clear'), '6');
  });

  testWidgets('a chip that matches nothing says which, and keeps the chips', (
    WidgetTester tester,
  ) async {
    await pumpTab(
      tester,
      jobs: UseSmileIDSampleMemoryJobsRepository(<UseSmileIDSampleJob>[
        UseSmileIDSampleJob(
          id: 'job_one',
          userId: 'user_one',
          product: UseSmileIDSampleProduct.values.first,
          status: UseSmileIDSampleStatus.clear,
          createdAtMillis: DateTime(2026, 7, 16, 12).millisecondsSinceEpoch,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.filterChip('blocked')));
    await tester.pumpAndSettle();

    expect(find.text('Nothing blocked'), findsOne);
    expect(find.text('Other filters still have verifications.'), findsOne);
    expect(
      byId(UseSmileIDSampleTestIds.filterChip('all')),
      findsOne,
      reason: 'a filter that matched nothing has to stay switchable',
    );
  });

  test('seeded jobs survive the process that seeded them', () async {
    await (await UseSmileIDSamplePreferencesJobsRepository.open()).seedFixtures(
      DateTime(2026, 7, 16).millisecondsSinceEpoch,
    );

    expect(
      await (await UseSmileIDSamplePreferencesJobsRepository.open()).read(),
      hasLength(11),
    );
  });

  test('a store this build cannot read is treated as no store', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      useSmileIDSampleJobsKey: 'not json',
    });

    expect(
      await (await UseSmileIDSamplePreferencesJobsRepository.open()).read(),
      isEmpty,
    );
  });
}

/// A store that answers only when told to, so the not-yet-answered frame can be looked at.
class _HeldJobsRepository implements UseSmileIDSampleJobsRepository {
  final Completer<List<UseSmileIDSampleJob>> _answer =
      Completer<List<UseSmileIDSampleJob>>();

  /// Lets the pending read complete.
  void answer(List<UseSmileIDSampleJob> jobs) => _answer.complete(jobs);

  @override
  Future<List<UseSmileIDSampleJob>?> read() => _answer.future;

  @override
  Future<void> seedFixtures(int nowMillis) async {}

  @override
  Future<int> remove(Set<String> ids) async => 0;

  @override
  Future<void> undoRemove() async {}
}
