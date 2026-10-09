import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_remove_jobs.dart';
import '../use_smileid_sample_routes.dart';

/// The verifications tab: the stored jobs, grouped by day, under the chips.
class UseSmileIDSampleVerificationsTab extends ConsumerStatefulWidget {
  /// Takes nothing; the jobs, the chip and the selection all come from their providers.
  const UseSmileIDSampleVerificationsTab({super.key});

  @override
  ConsumerState<UseSmileIDSampleVerificationsTab> createState() =>
      _UseSmileIDSampleVerificationsTabState();
}

/// How often the list asks about rows still processing while it is on screen.
const Duration _processingPoll = Duration(seconds: 5);

class _UseSmileIDSampleVerificationsTabState
    extends ConsumerState<UseSmileIDSampleVerificationsTab> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // After the first frame: the route this list sits in is not known before it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProcessing());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// No endpoint lists a partner's jobs, so the list asks about each processing row, and again while one still is.
  Future<void> _checkProcessing() async {
    _poll?.cancel();
    if (!mounted) {
      return;
    }
    // Under a job's details the list waits: that page checks its own row and says what changed.
    if (ModalRoute.of(context)?.isCurrent == false) {
      _poll = Timer(_processingPoll, _checkProcessing);
      return;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    final UseSmileIDSampleTokenSession? live = useSmileIDSampleLiveSession(
      ref.read(useSmileIDSampleSessionProvider).live,
      now,
    );
    final int stillProcessing = await ref
        .read(useSmileIDSampleJobsProvider.notifier)
        .refreshProcessingJobs(
          session: live == null
              ? null
              : UseSmileIDSampleRefreshSession(
                  token: live.token,
                  partnerId: live.partnerId,
                  expiresAtMillis: live.expiresAtMillis,
                ),
          nowMillis: now,
          source: ref.read(useSmileIDSampleJobStatusSourceProvider),
        );
    if (mounted && stillProcessing > 0) {
      _poll = Timer(_processingPoll, _checkProcessing);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A newly scanned session can answer for rows the last one could not.
    ref.listen(useSmileIDSampleSessionProvider, (_, _) => _checkProcessing());
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
