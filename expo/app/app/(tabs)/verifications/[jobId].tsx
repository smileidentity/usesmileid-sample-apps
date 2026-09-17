import {
  VerificationDetailsScreen,
  smileIDSampleRefreshLabel,
  useSmileIDSampleJobStore,
  type UseSmileIDSampleJobStatusSource,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useCallback, useEffect, useRef, useState } from 'react';

/// No scanned session exists yet, so every refresh reports why rather than doing nothing.
const source: UseSmileIDSampleJobStatusSource = {
  check: async () => ({ kind: 'noSession' }),
};

export default function VerificationDetails() {
  const router = useRouter();
  const { jobId } = useLocalSearchParams<{ jobId: string }>();
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const refresh = useSmileIDSampleJobStore((state) => state.refresh);
  const remove = useSmileIDSampleJobStore((state) => state.remove);
  const [refreshing, setRefreshing] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  /// The entry refresh runs once per row, so its own state write cannot re-trigger it.
  const refreshedOnEntry = useRef<string | null>(null);

  const job = (jobs ?? []).find((row) => row.id === jobId) ?? null;

  const run = useCallback(
    async (silent: boolean) => {
      if (jobId === undefined) return;
      if (!silent) setRefreshing(true);
      const outcome = await refresh(jobId, null, Date.now(), source);
      // Only the call that raised the spinner lowers it: the on-entry refresh is silent and shows
      // none, so clearing it there ended a pull-to-refresh the reader had started moments before.
      if (!silent) setRefreshing(false);
      // A silent refresh says nothing unless something actually changed.
      if (outcome !== null && (!silent || outcome.kind === 'updated')) {
        setNotice(smileIDSampleRefreshLabel(outcome));
      }
    },
    [jobId, refresh],
  );

  useEffect(() => {
    // Only a processing row can change, so only that one is refreshed on entry.
    if (job === null || job.status !== 'Processing') return;
    if (refreshedOnEntry.current === job.id) return;
    refreshedOnEntry.current = job.id;
    void run(true);
  }, [job, run]);

  return (
    <VerificationDetailsScreen
      state={{ job, jobId: jobId ?? '', refreshing, refreshNotice: notice }}
      onBack={() => router.back()}
      onDelete={() => {
        if (job !== null) void remove([job.id]);
        router.back();
      }}
      onRefresh={() => void run(false)}
      onCopy={() => undefined}
    />
  );
}
