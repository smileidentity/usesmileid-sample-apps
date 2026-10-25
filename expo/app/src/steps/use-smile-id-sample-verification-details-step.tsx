import {
  UseSmileIDSampleTransientNoticeHost,
  VerificationDetailsScreen,
  smileIDSampleRefreshLabel,
  useSmileIDSampleJobStore,
  smileIDSampleResultSelecting,
  useSmileIDSampleResultStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleTransientNotice,
  useSmileIDSampleStrings,
  UseSmileIDSampleStatus,
} from '@smileid/sample-ui';
import * as Clipboard from 'expo-clipboard';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform, StyleSheet, View } from 'react-native';

import type { UseSmileIDSampleStepScope } from '../navigation/use-smile-id-sample-navigation';
import { smileIDSampleStatusApi } from '../status/use-smile-id-sample-status-api';
import { useLaunchArgs } from '../use-smile-id-sample-launch';
import { useSmileIDSampleNoticeStyle } from '../use-smile-id-sample-notice-inset';

/// One verification, the job id its entry carries; also where a finished run lands.
export const UseSmileIDSampleVerificationDetailsStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const back = () => scope.navigator.back();
  const jobId = scope.entry.arg;
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const load = useSmileIDSampleJobStore((state) => state.load);
  const refresh = useSmileIDSampleJobStore((state) => state.refresh);
  const refreshUntilSettled = useSmileIDSampleJobStore((state) => state.refreshUntilSettled);
  const liveSessionId = useSmileIDSampleSessionStore((state) => state.live?.id ?? null);
  const remove = useSmileIDSampleJobStore((state) => state.remove);
  const [refreshing, setRefreshing] = useState(false);
  const notice = useSmileIDSampleTransientNotice();
  const args = useLaunchArgs();
  const result = useSmileIDSampleResultStore((state) => state.result);
  const showProbes = __DEV__ || args.probes;
  const noticeStyle = useSmileIDSampleNoticeStyle();
  const { show } = notice;
  /// Whether the processing row is being asked about, so its own state write cannot start a second check.
  const polling = useRef(false);
  /// Cleared on leaving, which is what ends a check still waiting out its backoff.
  const mounted = useRef(true);

  const job = (jobs ?? []).find((row) => row.id === jobId) ?? null;

  /// A pull, which raises the spinner and always answers, "still processing" included.
  const pull = useCallback(async () => {
    if (jobId === undefined) return;
    setRefreshing(true);
    const outcome = await refresh(jobId, useSmileIDSampleSessionStore.getState().live, Date.now(), smileIDSampleStatusApi);
    setRefreshing(false);
    if (outcome !== null) show({ message: smileIDSampleRefreshLabel(outcome, strings) });
  }, [jobId, refresh, show, strings]);

  useEffect(() => {
    // A cold link lands here without the list, which is otherwise the only screen that loads the store.
    if (jobs === null) void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    // Set again on every mount: StrictMode and Fast Refresh mount, clean up, then mount once more.
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  useEffect(() => {
    // Only a processing row can change, so only that one is asked about, and again while the server still has it processing.
    if (job === null || job.status !== UseSmileIDSampleStatus.Processing || polling.current) return;
    polling.current = true;
    void refreshUntilSettled(
      job.id,
      () => useSmileIDSampleSessionStore.getState().live,
      Date.now,
      smileIDSampleStatusApi,
      (millis) => new Promise((resolve) => setTimeout(() => resolve(mounted.current), millis)),
    )
      .then((outcome) => {
        // Silent unless something happened: "still processing" on every check is noise.
        if (mounted.current && outcome !== null && outcome.kind !== 'stillProcessing') {
          show({ message: smileIDSampleRefreshLabel(outcome, strings) });
        }
      })
      // A check that fails outright says nothing, as the silent one before it did; a pull still answers.
      .catch(() => undefined)
      .finally(() => {
        polling.current = false;
      });
    // The session is a dependency so a session linked after a check ended without one starts another.
  }, [job, liveSessionId, refreshUntilSettled, show, strings]);

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
        onRefresh={() => void pull()}
        onCopy={(label, value) => {
          Clipboard.setStringAsync(value)
            .then(() => {
              // Android 13 shows its own confirmation; below it there is none, and iOS shows none natively.
              if (Platform.OS === 'android' && Number(Platform.Version) < 33) {
                show({ message: `${label} copied` });
              }
            })
            .catch(() => show({ message: `${label} could not be copied` }));
        }}
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={noticeStyle} />
    </View>
  );
};

const styles = StyleSheet.create({
  host: { flex: 1 },
});
