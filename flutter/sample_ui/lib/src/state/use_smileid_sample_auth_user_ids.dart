import '../model/use_smileid_sample_job.dart';
import '../model/use_smileid_sample_status.dart';

/// This partner's enrolling runs in this environment, not refused or failed, newest first, one per user.
List<UseSmileIDSampleJob> useSmileIDSamplePreviousAuthUsers(
  List<UseSmileIDSampleJob> jobs, {
  required String? partnerId,
  required bool sandbox,
}) {
  if (partnerId == null) {
    return const <UseSmileIDSampleJob>[];
  }
  final List<UseSmileIDSampleJob> enrolled =
      jobs
          .where(
            (UseSmileIDSampleJob job) =>
                job.partnerId == partnerId &&
                job.sandbox == sandbox &&
                job.product.enrollsUser &&
                job.status != UseSmileIDSampleStatus.blocked &&
                job.status != UseSmileIDSampleStatus.error &&
                job.userId.trim().isNotEmpty,
          )
          .toList()
        ..sort(
          (UseSmileIDSampleJob a, UseSmileIDSampleJob b) =>
              b.createdAtMillis.compareTo(a.createdAtMillis),
        );
  final Set<String> seen = <String>{};
  return <UseSmileIDSampleJob>[
    for (final UseSmileIDSampleJob job in enrolled)
      if (seen.add(job.userId)) job,
  ];
}
