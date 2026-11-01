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
  /// The last refresh outcome, or a copy's confirmation while its window stands.
  String? _notice;

  /// Withdraws a copy's confirmation once its window closes; a refresh outcome has none.
  Timer? _noticeExpiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_refreshOnEntry()),
    );
  }

  @override
  void dispose() {
    _noticeExpiry?.cancel();
    super.dispose();
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
    if (!processing || !mounted) {
      return;
    }
    // Asked again with the list's backoff while the server still has it processing, until this page is left.
    final UseSmileIDSampleStatusRefresh? outcome = await ref
        .read(useSmileIDSampleJobsProvider.notifier)
        .refreshJobUntilSettled(
          jobId: widget.jobId,
          session: _session,
          source: ref.read(useSmileIDSampleJobStatusSourceProvider),
          wait: (Duration delay) async {
            await Future<void>.delayed(delay);
            return mounted;
          },
        );
    // Silent unless something happened: "still processing" on every check is noise.
    if (outcome == null ||
        outcome is UseSmileIDSampleStatusStillProcessing ||
        !mounted) {
      return;
    }
    _say(outcome);
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
      onCopy: (String label, String value) => unawaited(_copy(label, value)),
      notice: _notice,
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

  /// The live session as the store asks with it, read afresh for every check.
  UseSmileIDSampleRefreshSession? _session() {
    final UseSmileIDSampleTokenSession? live = useSmileIDSampleLiveSession(
      ref.read(useSmileIDSampleSessionProvider).live,
      DateTime.now().millisecondsSinceEpoch,
    );
    return live == null
        ? null
        : UseSmileIDSampleRefreshSession(
            token: live.token,
            partnerId: live.partnerId,
            expiresAtMillis: live.expiresAtMillis,
          );
  }

  /// A pull: asks the store what became of the job, and says whatever it decided.
  Future<void> _refresh() async {
    final UseSmileIDSampleStatusRefresh? outcome = await ref
        .read(useSmileIDSampleJobsProvider.notifier)
        .refreshJob(
          jobId: widget.jobId,
          session: _session(),
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          source: ref.read(useSmileIDSampleJobStatusSourceProvider),
        );
    // Already in flight: the notice standing is the one this refresh would have repeated.
    if (outcome == null || !mounted) {
      return;
    }
    _say(outcome);
  }

  /// Puts [outcome] in the notice, in the other three apps' words.
  void _say(UseSmileIDSampleStatusRefresh outcome) {
    _noticeExpiry?.cancel();
    setState(
      () => _notice = useSmileIDSampleRefreshLabel(outcome, context.strings),
    );
  }

  /// Copies [value], confirming it only where the platform does not, as the other three apps do.
  Future<void> _copy(String label, String value) async {
    final UseSmileIDSampleStrings strings = context.strings;
    try {
      await Clipboard.setData(ClipboardData(text: value));
    } on Object {
      _flash(strings.detailsCopyFailed(label: label));
      return;
    }
    if (!mounted ||
        await ref.read(useSmileIDSampleSystemConfirmsCopyProvider.future)) {
      return;
    }
    _flash(strings.detailsCopied(label: label));
  }

  /// Shows [message] for the notice window, restarting it if one already stands.
  void _flash(String message) {
    if (!mounted) {
      return;
    }
    _noticeExpiry?.cancel();
    setState(() => _notice = message);
    _noticeExpiry = Timer(ref.read(useSmileIDSampleNoticeWindowProvider), () {
      if (mounted) {
        setState(() => _notice = null);
      }
    });
  }
}
