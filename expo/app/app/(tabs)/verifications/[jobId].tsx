import {
  UseSmileIDSampleTransientNoticeHost,
  VerificationDetailsScreen,
  smileIDSampleRefreshLabel,
  useSmileIDSampleJobStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleTransientNotice,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { smileIDSampleStatusApi } from '../../../src/status/use-smile-id-sample-status-api';
import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';
import { useSmileIDSampleNoticeStyle } from '../../../src/use-smile-id-sample-notice-inset';
import { useCallback, useEffect, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';

export default function VerificationDetails() {
  const back = useSmileIDSampleBack('/verifications');
  const { jobId } = useLocalSearchParams<{ jobId: string }>();
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const refresh = useSmileIDSampleJobStore((state) => state.refresh);
  const remove = useSmileIDSampleJobStore((state) => state.remove);
  const [refreshing, setRefreshing] = useState(false);
  const notice = useSmileIDSampleTransientNotice();
  const noticeStyle = useSmileIDSampleNoticeStyle();
  const { show } = notice;
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
      // The entry refresh is silent only about "still processing", which every visit would otherwise repeat.
      if (outcome !== null && (!silent || outcome.kind !== 'stillProcessing')) {
        show({ message: smileIDSampleRefreshLabel(outcome) });
      }
    },
    [jobId, refresh, show],
  );

  useEffect(() => {
    // Only a processing row can change, so only that one is refreshed on entry.
    if (job === null || job.status !== 'Processing') return;
    if (refreshedOnEntry.current === job.id) return;
    refreshedOnEntry.current = job.id;
    void run(true);
  }, [job, run]);

  return (
    <View style={styles.host}>
      <VerificationDetailsScreen
        state={{ job, jobId: jobId ?? '', refreshing }}
        onBack={() => back()}
        onDelete={() => {
          if (job !== null) void remove([job.id]);
          back();
        }}
        onRefresh={() => void run(false)}
        onCopy={() => undefined}
      />
      {/* Past the system bar, which edge-to-edge draws over this route; a pushed screen has no nav bar to clear. */}
      <UseSmileIDSampleTransientNoticeHost state={notice} style={noticeStyle} />
    </View>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1 },
});
