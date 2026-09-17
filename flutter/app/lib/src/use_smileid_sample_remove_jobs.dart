import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import 'state/use_smileid_sample_providers.dart';

/// Hides rows from this app's list: the ONE handler both the swipe and the selection bar run.
///
/// Two apps' worth of experience says the paths must not diverge — a removal has to leave select
/// mode, show its confirmation and fall the filter back, whichever affordance fired it.
Future<void> useSmileIDSampleRemoveJobs(WidgetRef ref, Set<String> ids) async {
  // The pre-delete list minus the outgoing ids: the write has not landed yet, so asking the store
  // again here would answer with rows that are about to be gone.
  final List<UseSmileIDSampleJob> remaining =
      (ref.read(useSmileIDSampleJobsProvider).value ??
              const <UseSmileIDSampleJob>[])
          .where((UseSmileIDSampleJob job) => !ids.contains(job.id))
          .toList();
  final UseSmileIDSampleJobFilter filter = ref.read(
    useSmileIDSampleJobFilterProvider,
  );

  final int taken = await ref
      .read(useSmileIDSampleJobsProvider.notifier)
      .removeJobs(ids);
  ref.read(useSmileIDSampleSelectionProvider.notifier).setActive(false);
  if (taken == 0) {
    return;
  }
  ref.read(useSmileIDSampleRemovalNoticeProvider.notifier).show(taken);
  // Removing the last row of the ACTIVE filter falls back to All, or the reader is left staring at
  // an empty list under a chip they did not choose to be on.
  if (!remaining.any(filter.matches)) {
    ref
        .read(useSmileIDSampleJobFilterProvider.notifier)
        .select(UseSmileIDSampleJobFilter.all);
  }
}
