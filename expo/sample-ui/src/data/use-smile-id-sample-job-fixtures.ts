import type { UseSmileIDSampleJob } from '../model/use-smile-id-sample-job';
import { smileIDSampleProducts } from '../model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';

const HOURS_APART = 5;
const MILLIS_PER_HOUR = 60 * 60 * 1000;
const HTTP_OK = 200;
const HTTP_ACCEPTED = 202;

/// The eleven statuses the design's chip counts describe: All 11, Clear 6, Attention 2, Blocked 2.
const statuses: readonly UseSmileIDSampleStatus[] = [
  UseSmileIDSampleStatus.Clear,
  UseSmileIDSampleStatus.Processing,
  UseSmileIDSampleStatus.Clear,
  UseSmileIDSampleStatus.Attention,
  UseSmileIDSampleStatus.Blocked,
  UseSmileIDSampleStatus.Clear,
  UseSmileIDSampleStatus.Clear,
  UseSmileIDSampleStatus.Attention,
  UseSmileIDSampleStatus.Blocked,
  UseSmileIDSampleStatus.Clear,
  UseSmileIDSampleStatus.Clear,
];

const message = (status: UseSmileIDSampleStatus): string => {
  switch (status) {
    case UseSmileIDSampleStatus.Clear:
      return 'Approved';
    case UseSmileIDSampleStatus.Attention:
      return 'Provisional — needs review';
    case UseSmileIDSampleStatus.Blocked:
      return 'Rejected';
    case UseSmileIDSampleStatus.Processing:
      return 'Submitted, awaiting result';
  }
};

const padded = (value: number) => String(value).padStart(2, '0');

/// Reached only by the `seedJobs` launch argument, and identical to the other platforms' set so a
/// pair of goldens can be read against each other rather than squinted at.
export const smileIDSampleJobFixtures = (nowMillis: number): readonly UseSmileIDSampleJob[] =>
  statuses.map((status, index) => ({
    id: `job_${padded(index)}ky31za${padded((index * 7) % 100)}`,
    userId: `user_${padded(index)}ky31za${padded((index * 3) % 100)}`,
    product: smileIDSampleProducts[index % smileIDSampleProducts.length]!,
    status,
    createdAtMillis: nowMillis - index * HOURS_APART * MILLIS_PER_HOUR,
    message: message(status),
    httpStatus: status === UseSmileIDSampleStatus.Processing ? HTTP_ACCEPTED : HTTP_OK,
    sandbox: true,
    // A fixture persists no session at all, so a refresh reports "never submitted" before any
    // partner check is reached.
    sessionId: null,
    partnerId: null,
  }));
