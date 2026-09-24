import {
  UseSmileIDSampleTransientNoticeHost,
  VerificationDetailsScreen,
  smileIDSampleRefreshLabel,
  useSmileIDSampleJobStore,
  smileIDSampleResultSelecting,
  useSmileIDSampleResultStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleTransientNotice,
} from '@smileid/sample-ui';
import * as Clipboard from 'expo-clipboard';
import { useLocalSearchParams } from 'expo-router';

import { smileIDSampleStatusApi } from '../../../src/status/use-smile-id-sample-status-api';
import { useLaunchArgs } from '../../../src/use-smile-id-sample-launch';
import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';
import { useSmileIDSampleNoticeStyle } from '../../../src/use-smile-id-sample-notice-inset';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform, StyleSheet, View } from 'react-native';

export default function VerificationDetails() {
  const back = useSmileIDSampleBack('/verifications');
  const { jobId } = useLocalSearchParams<{ jobId: string }>();
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const load = useSmileIDSampleJobStore((state) => state.load);
  const refresh = useSmileIDSampleJobStore((state) => state.refresh);
  const remove = useSmileIDSampleJobStore((state) => state.remove);
  const [refreshing, setRefreshing] = useState(false);
  const notice = useSmileIDSampleTransientNotice();
  const args = useLaunchArgs();
  const result = useSmileIDSampleResultStore((state) => state.result);
  const showProbes = __DEV__ || args.probes;
  const noticeStyle = useSmileIDSampleNoticeStyle();
  const { show } = notice;
  /// The entry refresh runs once per row, so its own state write cannot re-trigger it.
  const refreshedOnEntry = useRef<string | null>(null);

  const job = (jobs ?? []).find((row) => row.id === jobId) ?? null;

  const run = useCallback(
    async (silent: boolean) => {
      if (jobId === undefined) return;
      if (!silent) setRefreshing(true);
      const outcome = await refresh(
        jobId,
        useSmileIDSampleSessionStore.getState().live,
        Date.now(),
        smileIDSampleStatusApi,
      );
      // Only the call that raised the spinner lowers it: the on-entry refresh is silent and shows
      // none, so clearing it there ended a pull-to-refresh the reader had started moments before.
      if (!silent) setRefreshing(false);
      // Silent on entry only about "still processing", which every visit would repeat.
      if (outcome !== null && (!silent || outcome.kind !== 'stillProcessing')) {
        show({ message: smileIDSampleRefreshLabel(outcome) });
      }
    },
    [jobId, refresh, show],
  );

  useEffect(() => {
    // A cold link lands here without the list, which is otherwise the only screen that loads the store.
    if (jobs === null) void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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
        state={{
          job,
          jobId: jobId ?? '',
          refreshing,
          pending: jobs === null,
          result: showProbes ? smileIDSampleResultSelecting(result, args.scenario, args.theme) : null,
        }}
        onBack={() => back()}
        onDelete={() => {
          if (job !== null) void remove([job.id]);
          back();
        }}
        onRefresh={() => void run(false)}
        onCopy={(label, value) => {
          void Clipboard.setStringAsync(value).then(() => {
            // Android 13 shows its own confirmation; below it there is none, and iOS shows none natively.
            if (Platform.OS === 'android' && Number(Platform.Version) < 33) {
              show({ message: `${label} copied` });
            }
          });
        }}
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={noticeStyle} />
    </View>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1 },
});
