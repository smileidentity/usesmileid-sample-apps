import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// Hiding a row: the two affordances that do it, and the four things a removal must also do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  UseSmileIDSampleJob job(String id, UseSmileIDSampleStatus status) =>
      UseSmileIDSampleJob(
        id: id,
        userId: 'user_$id',
        product: UseSmileIDSampleProduct.values.first,
        status: status,
        createdAtMillis: DateTime(2026, 7, 16, 12).millisecondsSinceEpoch,
      );

  late ProviderContainer container;

  Future<void> pumpList(
    WidgetTester tester,
    List<UseSmileIDSampleJob> jobs, {
    int? noticeWindow,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(
            UseSmileIDSampleMemoryJobsRepository(jobs),
          ),
          if (noticeWindow != null)
            useSmileIDSampleLaunchArgsProvider.overrideWithValue(
              UseSmileIDSampleLaunchArgs(noticeWindow: noticeWindow),
            ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(
            initialLocation: UseSmileIDSampleRoutes.verifications,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('the header action turns picking on and off', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
    ]);

    expect(find.text('Select'), findsOne);
    expect(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)), findsNothing);

    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOne);
    expect(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)), findsOne);
    expect(byId(UseSmileIDSampleTestIds.selectionBar), findsOne);
    expect(byId(UseSmileIDSampleTestIds.navProducts), findsNothing);

    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.selectionBar), findsNothing);
    expect(byId(UseSmileIDSampleTestIds.navProducts), findsOne);
  });

  // Entering select mode clears the picks; leaving it does NOT, so the bar still reads its count
  // while it animates away.
  testWidgets('picking starts empty every time it is turned on', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    expect(container.read(useSmileIDSampleSelectionProvider).ids, hasLength(1));

    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();

    expect(container.read(useSmileIDSampleSelectionProvider).ids, isEmpty);
  });

  testWidgets('the selection bar hides what was picked and confirms it', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
      job('b', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionRemove));
    await tester.pumpAndSettle();

    expect(find.text('1 verification hidden from App list'), findsOne);
    expect(byId(UseSmileIDSampleTestIds.toastUndo), findsOne);
    expect(container.read(useSmileIDSampleJobsProvider).value, hasLength(1));
    expect(
      container.read(useSmileIDSampleSelectionProvider).active,
      isFalse,
      reason: 'a removal always leaves select mode',
    );
  });

  testWidgets('Undo puts the batch back, and only once', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
      job('b', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionRemove));
    await tester.pumpAndSettle();

    await tester.tap(byId(UseSmileIDSampleTestIds.toastUndo));
    await tester.pumpAndSettle();

    expect(container.read(useSmileIDSampleJobsProvider).value, hasLength(2));
    expect(
      container.read(useSmileIDSampleRemovalNoticeProvider),
      isNull,
      reason: 'taking the action withdraws the offer',
    );

    await container.read(useSmileIDSampleJobsProvider.notifier).undoRemoval();
    expect(
      container.read(useSmileIDSampleJobsProvider).value,
      hasLength(2),
      reason: 'a second undo restores nothing',
    );
  });

  // The rule the two removal paths share: emptying the ACTIVE filter falls back to All, or the
  // reader is left staring at an empty list under a chip they did not choose.
  testWidgets('emptying the active filter falls back to All', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.blocked),
      job('b', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.filterChip('blocked')));
    await tester.pumpAndSettle();
    expect(
      container.read(useSmileIDSampleJobFilterProvider),
      UseSmileIDSampleJobFilter.blocked,
    );

    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionRemove));
    await tester.pumpAndSettle();

    expect(
      container.read(useSmileIDSampleJobFilterProvider),
      UseSmileIDSampleJobFilter.all,
    );
  });

  testWidgets('a filter with rows left is not disturbed by a removal', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
      job('b', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.filterChip('clear')));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionRemove));
    await tester.pumpAndSettle();

    expect(
      container.read(useSmileIDSampleJobFilterProvider),
      UseSmileIDSampleJobFilter.clear,
    );
  });

  testWidgets('the confirmation withdraws itself after its window', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionRemove));
    await tester.pumpAndSettle();
    expect(byId(UseSmileIDSampleTestIds.toast), findsOne);

    await tester.pump(useSmileIDSampleNoticeWindow);
    await tester.pumpAndSettle();

    expect(byId(UseSmileIDSampleTestIds.toast), findsNothing);
  });

  // The lane widens the window so a loaded runner cannot lose the Undo tap to the withdrawal.
  testWidgets('a launch argument sets the window the confirmation stands for', (
    WidgetTester tester,
  ) async {
    const int longer = 30;
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
    ], noticeWindow: longer);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionCheckbox(0)));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.selectionRemove));
    await tester.pumpAndSettle();

    // Past the product's window: with the argument ignored the confirmation is already gone here.
    await tester.pump(
      useSmileIDSampleNoticeWindow + const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(byId(UseSmileIDSampleTestIds.toast), findsOne);

    await tester.pump(const Duration(seconds: longer));
    await tester.pumpAndSettle();
    expect(byId(UseSmileIDSampleTestIds.toast), findsNothing);
  });

  // The OTHER removal path, and the one with no other coverage: it must reach the same handler, so
  // it confirms, exits select mode and falls the filter back exactly as the bar does.
  testWidgets('a swipe hides the row it was dragged across', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
      job('b', UseSmileIDSampleStatus.clear),
    ]);

    await tester.drag(
      byId(UseSmileIDSampleTestIds.jobRow(0)),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 verification hidden from App list'), findsOne);
    expect(container.read(useSmileIDSampleJobsProvider).value, hasLength(1));
  });

  testWidgets('a swipe cannot fire while rows are being picked', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();

    await tester.drag(
      byId(UseSmileIDSampleTestIds.jobRow(0)),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(container.read(useSmileIDSampleJobsProvider).value, hasLength(1));
    expect(byId(UseSmileIDSampleTestIds.toast), findsNothing);
  });

  testWidgets('a row does not open while rows are being picked', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, <UseSmileIDSampleJob>[
      job('a', UseSmileIDSampleStatus.clear),
    ]);
    await tester.tap(byId(UseSmileIDSampleTestIds.selectToggle));
    await tester.pumpAndSettle();
    await tester.tap(byId(UseSmileIDSampleTestIds.jobRow(0)));
    await tester.pumpAndSettle();

    expect(
      container.read(useSmileIDSampleSelectionProvider).ids,
      isEmpty,
      reason: 'the row body is not a second checkbox either',
    );
    expect(byId(UseSmileIDSampleTestIds.verificationsScreen), findsOne);
  });

  // Found on a device: with seedJobs on, a removal came straight BACK with a fresh timestamp.
  testWidgets('a removal is not undone by a seeded launch', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleMemoryJobsRepository store =
        UseSmileIDSampleMemoryJobsRepository();
    await useSmileIDSampleApplyLaunch(
      const UseSmileIDSampleLaunchArgs(seedJobs: true),
      store,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(store),
          useSmileIDSampleLaunchArgsProvider.overrideWithValue(
            const UseSmileIDSampleLaunchArgs(seedJobs: true),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleRouter(
            initialLocation: UseSmileIDSampleRoutes.verifications,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(useSmileIDSampleJobsProvider).value, hasLength(11));

    await tester.drag(
      byId(UseSmileIDSampleTestIds.jobRow(0)),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(container.read(useSmileIDSampleJobsProvider).value, hasLength(10));
  });

  group('the store', () {
    test('reports what it TOOK, not what was asked for', () async {
      final UseSmileIDSamplePreferencesJobsRepository store =
          UseSmileIDSamplePreferencesJobsRepository(
            await SharedPreferences.getInstance(),
          );
      await store.seedFixtures(DateTime(2026, 7, 16).millisecondsSinceEpoch);
      final List<UseSmileIDSampleJob> stored = (await store.read())!;

      expect(await store.remove(<String>{stored.first.id, 'never-existed'}), 1);
    });

    // A no-op must not clear the undo, or an id that matched nothing silently spends a batch the
    // reader can still put back.
    test('an id matching nothing leaves the undoable batch alone', () async {
      final UseSmileIDSamplePreferencesJobsRepository store =
          UseSmileIDSamplePreferencesJobsRepository(
            await SharedPreferences.getInstance(),
          );
      await store.seedFixtures(DateTime(2026, 7, 16).millisecondsSinceEpoch);
      final List<UseSmileIDSampleJob> stored = (await store.read())!;

      await store.remove(<String>{stored.first.id});
      expect(await store.remove(<String>{'never-existed'}), 0);
      await store.undoRemove();

      expect(await store.read(), hasLength(11));
    });

    test('a removal survives the process that made it', () async {
      final UseSmileIDSamplePreferencesJobsRepository store =
          await UseSmileIDSamplePreferencesJobsRepository.open();
      await store.seedFixtures(DateTime(2026, 7, 16).millisecondsSinceEpoch);
      final List<UseSmileIDSampleJob> stored = (await store.read())!;
      await store.remove(<String>{stored.first.id});

      expect(
        await (await UseSmileIDSamplePreferencesJobsRepository.open()).read(),
        hasLength(10),
      );
    });
  });
}
