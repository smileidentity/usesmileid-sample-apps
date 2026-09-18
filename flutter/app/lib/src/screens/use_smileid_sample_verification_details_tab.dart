import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
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

  /// Re-reads the job, or says why it cannot be re-read.
  Future<void> _refresh() async {
    final String notice =
        _stored()?.refreshBlockedReason ?? 'Nothing stored to refresh';
    if (mounted) {
      setState(() => _refreshNotice = notice);
    }
  }
}
