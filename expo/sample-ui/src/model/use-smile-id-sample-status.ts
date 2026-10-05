import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// The four job statuses, Title case as the design sets them.
export const UseSmileIDSampleStatus = {
  Clear: 'Clear',
  Attention: 'Attention',
  Blocked: 'Blocked',
  Processing: 'Processing',
} as const;

export type UseSmileIDSampleStatus = (typeof UseSmileIDSampleStatus)[keyof typeof UseSmileIDSampleStatus];

/// The pill's text in the app's language.
export const smileIDSampleStatusLabel = (status: UseSmileIDSampleStatus, strings: UseSmileIDSampleStrings): string => {
  switch (status) {
    case UseSmileIDSampleStatus.Clear:
      return strings.statusClear;
    case UseSmileIDSampleStatus.Attention:
      return strings.statusAttention;
    case UseSmileIDSampleStatus.Blocked:
      return strings.statusBlocked;
    case UseSmileIDSampleStatus.Processing:
      return strings.statusProcessing;
  }
};

/// The feedback role each status draws its soft pill from.
export const smileIDSampleStatusRole = (status: UseSmileIDSampleStatus): string => {
  switch (status) {
    case UseSmileIDSampleStatus.Clear:
      return 'success';
    case UseSmileIDSampleStatus.Attention:
      return 'warning';
    case UseSmileIDSampleStatus.Blocked:
      return 'error';
    case UseSmileIDSampleStatus.Processing:
      return 'info';
  }
};

/// Resolves a persisted or restored status by lookup, so a rename cannot crash a restore.
export const smileIDSampleStatusFrom = (
  value: string | null | undefined,
  fallback: UseSmileIDSampleStatus = UseSmileIDSampleStatus.Processing,
): UseSmileIDSampleStatus => {
  const match = Object.values(UseSmileIDSampleStatus).find((status) => status === value);
  return match ?? fallback;
};
