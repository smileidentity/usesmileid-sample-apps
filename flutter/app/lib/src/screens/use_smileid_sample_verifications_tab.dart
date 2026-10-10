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

/// How soon a hidden list looks again to see whether it is back on screen; it asks the server nothing meanwhile.
const Duration _hiddenRecheck = Duration(seconds: 5);

class _UseSmileIDSampleVerificationsTabState
    extends ConsumerState<UseSmileIDSampleVerificationsTab> {
  Timer? _poll;

  /// Bumped by every check, so only the newest one reschedules: a session scanned mid-check would otherwise start a second loop.
  int _generation = 0;

  /// The checks made since the list last found work, which sets the wait before the next.
  int _attempt = 0;

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
  Future<void> _checkProcessing({bool restart = false}) async {
    _poll?.cancel();
    final int generation = ++_generation;
    if (restart) {
      _attempt = 0;
    }
    if (!mounted) {
      return;
    }
    // Under a job's details, or on another tab, the list waits: that page checks its own row and says what changed.
    if (ModalRoute.of(context)?.isCurrent == false ||
        !TickerMode.valuesOf(context).enabled) {
      _poll = Timer(_hiddenRecheck, _checkProcessing);
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
    if (!mounted || generation != _generation || stillProcessing == 0) {
      return;
    }
    final Duration? wait = useSmileIDSampleProcessingPollDelay(_attempt++);
    if (wait != null) {
      _poll = Timer(wait, _checkProcessing);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A newly scanned session can answer for rows the last one could not.
    ref.listen(
      useSmileIDSampleSessionProvider,
      (_, _) => _checkProcessing(restart: true),
    );
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
