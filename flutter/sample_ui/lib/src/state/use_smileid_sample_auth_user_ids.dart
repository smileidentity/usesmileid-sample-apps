import '../model/use_smileid_sample_job.dart';
import '../model/use_smileid_sample_status.dart';

/// The user IDs SmartSelfie Authentication can run as: from jobs that enrol a user and were not refused or failed, newest first, once each.
List<String> useSmileIDSamplePreviousAuthUserIds(
  List<UseSmileIDSampleJob> jobs,
) {
  final List<UseSmileIDSampleJob> enrolled =
      jobs
          .where(
            (UseSmileIDSampleJob job) =>
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
  return <String>[
    for (final UseSmileIDSampleJob job in enrolled)
      if (seen.add(job.userId)) job.userId,
  ];
}
