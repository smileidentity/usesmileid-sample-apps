import {
  VerificationDetailsScreen,
  smileIDSampleRefreshLabel,
  useSmileIDSampleJobStore,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { smileIDSampleStatusApi } from '../../../src/status/use-smile-id-sample-status-api';
import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';
import { useCallback, useEffect, useRef, useState } from 'react';

export default function VerificationDetails() {
  const back = useSmileIDSampleBack('/verifications');
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
      // The store decides whether the session may ask, including for a row another partner submitted.
      const outcome = await refresh(
        jobId,
        useSmileIDSampleSessionStore.getState().live,
        Date.now(),
        smileIDSampleStatusApi,
      );
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
      onBack={() => back()}
      onDelete={() => {
        if (job !== null) void remove([job.id]);
        back();
      }}
      onRefresh={() => void run(false)}
      onCopy={() => undefined}
    />
  );
}
