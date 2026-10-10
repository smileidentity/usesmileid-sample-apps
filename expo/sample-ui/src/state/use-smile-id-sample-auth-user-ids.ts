import type { UseSmileIDSampleJob } from '../model/use-smile-id-sample-job';
import { smileIDSampleProductEnrollsUser } from '../model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';

/// The user IDs SmartSelfie Authentication can run as: this partner's jobs in this environment that enrol a user and were not refused or failed, newest first, once each.
export const smileIDSamplePreviousAuthUserIds = (
  jobs: readonly UseSmileIDSampleJob[],
  partnerId: string | null,
  sandbox: boolean,
): string[] => [
  ...new Set(
    jobs
      .filter(
        (job) =>
          partnerId !== null &&
          job.partnerId === partnerId &&
          job.sandbox === sandbox &&
          smileIDSampleProductEnrollsUser(job.product) &&
          job.status !== UseSmileIDSampleStatus.Blocked &&
          job.status !== UseSmileIDSampleStatus.Error &&
          job.userId.trim().length > 0,
      )
      .sort((a, b) => b.createdAtMillis - a.createdAtMillis)
      .map((job) => job.userId),
  ),
];
