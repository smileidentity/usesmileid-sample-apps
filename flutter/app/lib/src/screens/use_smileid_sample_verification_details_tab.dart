import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../flow/use_smileid_sample_token_binding_rules.dart';
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
    // Only a processing row can change, and a just-submitted job lands here processing.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_refreshOnEntry()),
    );
  }

  Future<void> _refreshOnEntry() async {
    // Waits for the store's first answer, so a cold link cannot read an empty list and skip.
    final List<UseSmileIDSampleJob> jobs = await ref.read(
      useSmileIDSampleJobsProvider.future,
    );
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
      job: found == null
          ? const UseSmileIDSampleJobLookup.none()
          : UseSmileIDSampleJobLookup.found(found),
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
    // The live session, not the row's: the store matches on partner, so a new session reads old rows.
    final UseSmileIDSampleTokenSession? live = useSmileIDSampleLiveSession(
      ref.read(useSmileIDSampleSessionProvider).live,
      UseSmileIDSampleScenario.normal,
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
    // Silent unless something happened: "still processing" on every visit is noise.
    if (onEntry && outcome is UseSmileIDSampleStatusStillProcessing) {
      return;
    }
    setState(() => _refreshNotice = useSmileIDSampleRefreshLabel(outcome));
  }
}
