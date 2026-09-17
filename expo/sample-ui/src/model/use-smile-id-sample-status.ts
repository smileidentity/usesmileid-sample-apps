/// The four job statuses, Title case as the design sets them.
export const UseSmileIDSampleStatus = {
  Clear: 'Clear',
  Attention: 'Attention',
  Blocked: 'Blocked',
  Processing: 'Processing',
} as const;

export type UseSmileIDSampleStatus = (typeof UseSmileIDSampleStatus)[keyof typeof UseSmileIDSampleStatus];

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
