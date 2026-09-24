import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../state/use_smileid_sample_flow_result_provider.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_remove_jobs.dart';

/// One verification's detail page, pushed inside the verifications tab so back stays within it.
class UseSmileIDSampleVerificationDetailsTab extends ConsumerStatefulWidget {
  /// [jobId] comes from the route, and may name a job this build never stored.
  const UseSmileIDSampleVerificationDetailsTab({
    required this.jobId,
    required this.onBack,
    super.key,
  });

  /// The id the route carried.
  final String jobId;

  /// Leaves the page.
  final VoidCallback onBack;

  @override
  ConsumerState<UseSmileIDSampleVerificationDetailsTab> createState() =>
      _UseSmileIDSampleVerificationDetailsTabState();
}

class _UseSmileIDSampleVerificationDetailsTabState
    extends ConsumerState<UseSmileIDSampleVerificationDetailsTab> {
  String? _refreshNotice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_refreshOnEntry()),
    );
  }

  Future<void> _refreshOnEntry() async {
    final List<UseSmileIDSampleJob> jobs;
    try {
      jobs = await ref.read(useSmileIDSampleJobsProvider.future);
    } on Object {
      // A failed read already shows as the empty state; there is nothing to refresh.
      return;
    }
    final bool processing = jobs.any(
      (UseSmileIDSampleJob it) =>
          it.id == widget.jobId &&
          it.status == UseSmileIDSampleStatus.processing,
    );
    if (processing && mounted) {
      await _refresh(onEntry: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleJob? found = _stored();
    return UseSmileIDSampleVerificationDetailsScreen(
      jobId: widget.jobId,
      result: ref.watch(useSmileIDSampleShowProbesProvider)
          ? ref.watch(useSmileIDSampleFlowResultProvider)
          : null,
      job: switch ((found, ref.watch(useSmileIDSampleJobsProvider))) {
        (final UseSmileIDSampleJob job, _) => UseSmileIDSampleJobLookup.found(
          job,
        ),
        // Pending only while the first read runs; a failed read answers "none", not a blank page.
        (
          null,
          AsyncValue<List<UseSmileIDSampleJob>>(
            hasValue: false,
            hasError: false,
          ),
        ) =>
          const UseSmileIDSampleJobLookup.pending(),
        (null, _) => const UseSmileIDSampleJobLookup.none(),
      },
      onBack: widget.onBack,
      // Deleting here leaves the page first, and the LIST shows the confirmation once it rebuilds:
      // the same handler, so the undo offer and the filter fallback are not lost with the page.
      onDelete: found == null
          ? null
          : () {
              widget.onBack();
              useSmileIDSampleRemoveJobs(ref, <String>{found.id});
            },
      onRefresh: _refresh,
      onCopy: (String label, String value) =>
          Clipboard.setData(ClipboardData(text: value)),
      refreshNotice: _refreshNotice,
    );
  }

  UseSmileIDSampleJob? _stored() {
    for (final UseSmileIDSampleJob job
        in ref.watch(useSmileIDSampleJobsProvider).value ??
            const <UseSmileIDSampleJob>[]) {
      if (job.id == widget.jobId) {
        return job;
      }
    }
    return null;
  }

  /// Asks the store what became of the job, and says whatever it decided.
  Future<void> _refresh({bool onEntry = false}) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final UseSmileIDSampleTokenSession? live = useSmileIDSampleLiveSession(
      ref.read(useSmileIDSampleSessionProvider).live,
      now,
    );
    final UseSmileIDSampleStatusRefresh? outcome = await ref
        .read(useSmileIDSampleJobsProvider.notifier)
        .refreshJob(
          jobId: widget.jobId,
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
    // Already in flight: the notice standing is the one this refresh would have repeated.
    if (outcome == null || !mounted) {
      return;
    }
    if (onEntry && outcome is UseSmileIDSampleStatusStillProcessing) {
      return;
    }
    setState(() => _refreshNotice = useSmileIDSampleRefreshLabel(outcome));
  }
}
