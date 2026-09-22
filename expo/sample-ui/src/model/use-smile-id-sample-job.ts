import {
  smileIDSampleProductFrom,
  smileIDSampleProducts,
  type UseSmileIDSampleProduct,
} from './use-smile-id-sample-product';
import { UseSmileIDSampleStatus, smileIDSampleStatusFrom } from './use-smile-id-sample-status';

const SHORT_ID_LENGTH = 8;

/// One submitted verification. `createdAtMillis` is absolute, so grouping never depends on when it is read.
export type UseSmileIDSampleJob = {
  readonly id: string;
  readonly userId: string;
  readonly product: UseSmileIDSampleProduct;
  readonly status: UseSmileIDSampleStatus;
  readonly createdAtMillis: number;
  readonly message: string;
  /// The response code, not its display text: the reason phrase is composed where the row is drawn.
  readonly httpStatus: number | null;
  /// The environment at submission time: a row outlives the toggle that produced it.
  readonly sandbox: boolean;
  /// The session the run submitted under; null on a fixture token.
  readonly sessionId: string | null;
  /// The partner the run submitted under; a later session's refresh matches on it.
  readonly partnerId: string | null;
};

const short = (value: string) =>
  value.length <= SHORT_ID_LENGTH ? value : `${value.slice(0, SHORT_ID_LENGTH)}…`;

/// The design truncates the job id in the list and on the details row; the full one is still copyable.
export const smileIDSampleJobShortId = (job: UseSmileIDSampleJob) => short(job.id);

export const smileIDSampleJobShortUserId = (job: UseSmileIDSampleJob) => short(job.userId);

/// Rebuilds a row read back from storage, resolving both enums by lookup so a rename cannot crash a restore.
export const smileIDSampleJobFrom = (raw: Record<string, unknown>): UseSmileIDSampleJob | null => {
  // The id is the one field with no sensible substitute: a row nothing can address is not a row.
  if (typeof raw.id !== 'string' || raw.id.length === 0) return null;
  return {
    id: raw.id,
    userId: typeof raw.userId === 'string' ? raw.userId : '',
    // Substituted rather than dropped, as Android and iOS do: a removed product must not take a
    // user's history with it, and the row still says everything else it recorded.
    product:
      smileIDSampleProductFrom(typeof raw.product === 'string' ? raw.product : null) ??
      smileIDSampleProducts[0]!,
    status: smileIDSampleStatusFrom(typeof raw.status === 'string' ? raw.status : null),
    createdAtMillis: typeof raw.createdAtMillis === 'number' ? raw.createdAtMillis : 0,
    message: typeof raw.message === 'string' ? raw.message : '',
    httpStatus: typeof raw.httpStatus === 'number' ? raw.httpStatus : null,
    sandbox: raw.sandbox !== false,
    sessionId: typeof raw.sessionId === 'string' ? raw.sessionId : null,
    partnerId: typeof raw.partnerId === 'string' ? raw.partnerId : null,
  };
};

/// The filters above the list. `All` is not a status, which is why this is not the status set.
export type UseSmileIDSampleJobFilter = {
  readonly id: string;
  readonly label: string;
  readonly status: UseSmileIDSampleStatus | null;
};

export const smileIDSampleJobFilters: readonly UseSmileIDSampleJobFilter[] = [
  { id: 'all', label: 'All', status: null },
  { id: 'clear', label: 'Clear', status: UseSmileIDSampleStatus.Clear },
  { id: 'attention', label: 'Attention', status: UseSmileIDSampleStatus.Attention },
  { id: 'blocked', label: 'Blocked', status: UseSmileIDSampleStatus.Blocked },
];

export const smileIDSampleJobMatches = (
  filter: UseSmileIDSampleJobFilter,
  job: UseSmileIDSampleJob,
) => filter.status === null || job.status === filter.status;

/// The reason phrase, composed where the row is drawn rather than stored beside the code.
export const smileIDSampleHttpLabel = (code: number | null): string | null => {
  if (code === null) return null;
  const phrases: Record<number, string> = {
    200: 'OK',
    202: 'Accepted',
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
    503: 'Service Unavailable',
  };
  const phrase = phrases[code];
  return phrase === undefined ? String(code) : `${code} ${phrase}`;
};
