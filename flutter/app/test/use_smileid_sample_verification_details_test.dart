import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  late ProviderContainer container;

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(
            UseSmileIDSampleMemoryJobsRepository(<UseSmileIDSampleJob>[job]),
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

  // The question the shell's PopScope raises: it blocks a pop on any tab but the first, so a
  // pushed page inside the verifications tab must still pop to its OWN list rather than jumping to
  // products. The branch navigator has to win, and this is the only route that can prove it.
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

  // The back control itself is asserted in sample_ui, where its semantics are reachable. It
  // carries no `sample_*` id — the spec gives the details screen none — so a device flow reaches
  // it the way the twin's flows do, with system back, which the test above drives.

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

  testWidgets('a pull says why the job cannot be re-read', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, UseSmileIDSampleRoutes.verificationDetails(job.id));

    await tester.fling(
      byId(UseSmileIDSampleTestIds.detailsRefresh),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Not submitted under a scanned token'), findsOne);
  });
}
