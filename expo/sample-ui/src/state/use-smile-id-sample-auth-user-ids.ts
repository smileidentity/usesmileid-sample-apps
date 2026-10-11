import type { UseSmileIDSampleJob } from '../model/use-smile-id-sample-job';
import { smileIDSampleProductEnrollsUser } from '../model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';

/// This partner's enrolling runs in this environment, not refused or failed, newest first, one per user.
export const smileIDSamplePreviousAuthUsers = (
  jobs: readonly UseSmileIDSampleJob[],
  partnerId: string | null,
  sandbox: boolean,
): UseSmileIDSampleJob[] => {
  const seen = new Set<string>();
  return jobs
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
    .filter((job) => {
      if (seen.has(job.userId)) return false;
      seen.add(job.userId);
      return true;
    });
};
