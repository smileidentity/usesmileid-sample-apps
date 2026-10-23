import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import 'state/use_smileid_sample_providers.dart';

/// Hides rows from this app's list: the ONE handler both the swipe and the selection bar run.
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
  // Read first: a delete from a job's page leaves it, so its ref is gone before the write lands.
  final UseSmileIDSampleSelectionNotifier selection = ref.read(
    useSmileIDSampleSelectionProvider.notifier,
  );
  final UseSmileIDSampleRemovalNoticeNotifier notice = ref.read(
    useSmileIDSampleRemovalNoticeProvider.notifier,
  );
  final UseSmileIDSampleJobFilterNotifier filters = ref.read(
    useSmileIDSampleJobFilterProvider.notifier,
  );

  final int taken = await ref
      .read(useSmileIDSampleJobsProvider.notifier)
      .removeJobs(ids);
  selection.setActive(false);
  if (taken == 0) {
    return;
  }
  notice.show(taken);
  // Removing the last row of the ACTIVE filter falls back to All, or the reader is left staring at
  // an empty list under a chip they did not choose to be on.
  if (!remaining.any(filter.matches)) {
    filters.select(UseSmileIDSampleJobFilter.all);
  }
}
