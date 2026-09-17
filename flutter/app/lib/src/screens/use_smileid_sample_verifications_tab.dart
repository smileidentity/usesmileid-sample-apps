import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_remove_jobs.dart';
import '../use_smileid_sample_routes.dart';

/// The verifications tab: the stored jobs, grouped by day, under the four chips.
///
/// A launch with no arguments shows the empty state, because fixtures reach a screen only through
/// `seedJobs` and never as the store's default.
class UseSmileIDSampleVerificationsTab extends ConsumerWidget {
  /// Takes nothing; the jobs, the chip and the selection all come from their providers.
  const UseSmileIDSampleVerificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UseSmileIDSampleJob>> jobs = ref.watch(
      useSmileIDSampleJobsProvider,
    );
    final UseSmileIDSampleSelection selection = ref.watch(
      useSmileIDSampleSelectionProvider,
    );
    return UseSmileIDSampleVerificationsScreen(
      state: UseSmileIDSampleVerificationsState(
        // Null while the store is still answering, which is the state that draws no empty text.
        jobs: jobs.value,
        // Midnight rather than the clock: the day headers change once a day, and passing a ticking
        // value would regroup the whole list every second for a string that did not move.
        nowMillis: useSmileIDSampleStartOfDayMillis(
          DateTime.now().millisecondsSinceEpoch,
        ),
        filter: ref.watch(useSmileIDSampleJobFilterProvider),
        selectMode: selection.active,
        selected: selection.ids,
        removedCount: ref.watch(useSmileIDSampleRemovalNoticeProvider),
      ),
      onFilterChanged: ref
          .read(useSmileIDSampleJobFilterProvider.notifier)
          .select,
      onJobTap: (UseSmileIDSampleJob job) =>
          context.go(UseSmileIDSampleRoutes.verificationDetails(job.id)),
      onSelectModeChanged: ref
          .read(useSmileIDSampleSelectionProvider.notifier)
          .setActive,
      onSelectionChanged: ref
          .read(useSmileIDSampleSelectionProvider.notifier)
          .select,
      onRemove: (Set<String> ids) => useSmileIDSampleRemoveJobs(ref, ids),
      onUndo: () {
        ref.read(useSmileIDSampleRemovalNoticeProvider.notifier).dismiss();
        ref.read(useSmileIDSampleJobsProvider.notifier).undoRemoval();
      },
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }
}
