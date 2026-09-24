import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_flow_result_provider.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The detail page: reaching it, what it shows, and what it does with a job it cannot find.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final UseSmileIDSampleJob job = UseSmileIDSampleJob(
    id: 'job_00ky31za00',
    userId: 'user_00ky31za00',
    product: UseSmileIDSampleProduct.values.first,
    status: UseSmileIDSampleStatus.clear,
    createdAtMillis: DateTime.utc(
      2026,
      7,
      16,
      13,
      3,
      41,
    ).millisecondsSinceEpoch,
    message: 'Approved',
    httpStatus: 200,
  );

  /// A row a real run would write: stored, and carrying the session it submitted under.
  final UseSmileIDSampleJob submitted = UseSmileIDSampleJob(
    id: 'job_00ky31za77',
    userId: 'user_00ky31za77',
    product: UseSmileIDSampleProduct.values.first,
    status: UseSmileIDSampleStatus.processing,
    createdAtMillis: DateTime.utc(2026, 7, 16, 14).millisecondsSinceEpoch,
    message: 'Submitted, awaiting result',
    httpStatus: 202,
    sessionId: 'session-1',
    partnerId: 'partner-1',
  );

  late ProviderContainer container;

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    List<UseSmileIDSampleJob>? stored,
    UseSmileIDSampleJobsRepository? repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(
            repository ??
                UseSmileIDSampleMemoryJobsRepository(
                  stored ?? <UseSmileIDSampleJob>[job],
                ),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(initialLocation: location),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('a row opens the page', (WidgetTester tester) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verifications);
    await tester.tap(byId(UseSmileIDSampleTestIds.jobRow(0)));
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.verificationDetailsScreen), findsOne);
  });

  // The question the shell's PopScope raises: it blocks a pop on any tab but the first.
  testWidgets('system back from the page returns to its own list', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verifications);
    await tester.tap(byId(UseSmileIDSampleTestIds.jobRow(0)));
    await tester.pumpAndSettle();

    final bool handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
    expect(
      byId(UseSmileIDSampleTestIds.productsScreen),
      findsNothing,
      reason: 'the branch navigator pops before the shell intercepts',
    );
  });

  // The back control itself is asserted in sample_ui, where its semantics are reachable.

  // It is inside the tab's branch, and R13 decides the bar by DESTINATION rather than by branch
  // membership — which is the defect R13 was written for.
  testWidgets('the page carries no nav bar, though it is inside the tab', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verificationDetails(job.id));

    expect(byId(UseSmileIDSampleTestIds.verificationDetailsScreen), findsOne);
    expect(byId(UseSmileIDSampleTestIds.navProducts), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.navToken), findsNothing);
  });

  testWidgets('it shows the five fields the design lists, in order', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verificationDetails(job.id));

    for (final String field in <String>[
      'createdAt',
      'jobId',
      'message',
      'status',
      'userId',
    ]) {
      expect(
        byId(UseSmileIDSampleTestIds.detailField(field)),
        findsOne,
        reason: field,
      );
    }
    expect(find.text('2026-07-16T13:03:41.000Z'), findsOne);
    expect(find.text('200 OK'), findsOne);
    expect(byId(UseSmileIDSampleTestIds.statusBadge), findsOne);
  });

  test('the detail page uses its own badge id, not the row s', () {
    expect(
      UseSmileIDSampleTestIds.statusBadge,
      isNot(UseSmileIDSampleTestIds.jobRowStatus),
    );
  });

  testWidgets('only the two id rows offer a copy control', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verificationDetails(job.id));

    expect(byId(UseSmileIDSampleTestIds.detailCopy('jobId')), findsOne);
    expect(byId(UseSmileIDSampleTestIds.detailCopy('userId')), findsOne);
    expect(byId(UseSmileIDSampleTestIds.detailCopy('message')), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.detailCopy('status')), findsNothing);
  });

  // A deep link can name a job this build never stored, which is a reachable state rather than an
  // error — so the page says which id it looked for.
  testWidgets('a job it never stored gets the empty state, naming the id', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.verificationDetails('job_never_existed'),
    );

    expect(byId(UseSmileIDSampleTestIds.detailsEmpty), findsOne);
    expect(find.text('No verification here'), findsOne);
    expect(find.text('Nothing stored for jobId = job_never_existed'), findsOne);
  });

  testWidgets('the empty state offers no delete, having nothing to delete', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.verificationDetails('job_never_existed'),
    );

    expect(byId(UseSmileIDSampleTestIds.detailsDelete), findsNothing);
  });

  // Deleting leaves the page, so the confirmation has to be shown by the LIST once it rebuilds —
  // the same handler, or the undo offer and the filter fallback go with the page.
  testWidgets('deleting returns to the list and the list confirms it', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verificationDetails(job.id));
    await tester.tap(byId(UseSmileIDSampleTestIds.detailsDelete));
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
    expect(find.text('1 verification hidden from App list'), findsOne);
    expect(byId(UseSmileIDSampleTestIds.toastUndo), findsOne);
    expect(container.read(useSmileIDSampleJobsProvider).value, isEmpty);
  });

  testWidgets('a cold link claims no absence before the store has answered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(
            _SlowReadRepository(<UseSmileIDSampleJob>[job]),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(
            initialLocation: UseSmileIDSampleRoutes.verificationDetails(job.id),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(byId(UseSmileIDSampleTestIds.verificationDetailsScreen), findsOne);
    expect(byId(UseSmileIDSampleTestIds.detailsEmpty), findsNothing);

    await tester.pump(_SlowReadRepository.delay);
    await tester.pumpAndSettle();
    expect(find.text('Approved'), findsOne);
  });

  testWidgets('a failed store read says the job is missing, not a blank page', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.verificationDetails(job.id),
      repository: _FailingReadRepository(),
    );
    expect(byId(UseSmileIDSampleTestIds.detailsEmpty), findsOne);
  });

  Future<void> pull(WidgetTester tester) async {
    await tester.fling(
      byId(UseSmileIDSampleTestIds.detailsRefresh),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a pull on a row that never submitted says so', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verificationDetails(job.id));

    await pull(tester);

    expect(find.text('Not submitted under a scanned token'), findsOne);
  });

  // The fall-through the store replaced: a stored row was told nothing was stored to refresh.
  testWidgets('a pull on a submitted row asks for a session, not for a row', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.verificationDetails(submitted.id),
      stored: <UseSmileIDSampleJob>[submitted],
    );

    await pull(tester);

    expect(find.text('Scan a token first'), findsOne);
    expect(find.text('Nothing stored to refresh'), findsNothing);
  });

  testWidgets('a job added through the notifier reaches the list', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verifications);

    await container
        .read(useSmileIDSampleJobsProvider.notifier)
        .addJob(submitted);
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.jobRow(1)), findsOne);
  });

  // Debug builds show probes, which is what `flutter test` runs as.
  testWidgets('the last run is on the page, even for a job never stored', (
    WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      UseSmileIDSampleRoutes.verificationDetails('job_none'),
    );
    container
        .read(useSmileIDSampleFlowResultProvider.notifier)
        .record(UseSmileIDSampleFlowStatus.cancelled);
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.detailsEmpty), findsOne);
    expect(byId(UseSmileIDSampleTestIds.resultCard), findsOne);
    expect(
      find.descendant(
        of: byId(UseSmileIDSampleTestIds.resultResultCount),
        matching: find.text('1'),
      ),
      findsOne,
    );
  });
}

class _SlowReadRepository extends UseSmileIDSampleMemoryJobsRepository {
  _SlowReadRepository(super.initial);

  static const Duration delay = Duration(milliseconds: 300);

  @override
  Future<List<UseSmileIDSampleJob>?> read() async {
    await Future<void>.delayed(delay);
    return super.read();
  }
}

class _FailingReadRepository extends UseSmileIDSampleMemoryJobsRepository {
  @override
  Future<List<UseSmileIDSampleJob>?> read() async => throw StateError('disk');
}
