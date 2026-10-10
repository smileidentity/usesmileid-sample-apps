import {
  UseSmileIDSampleTransientNoticeHost,
  VerificationsScreen,
  smileIDSampleProcessingPollDelayMillis,
  smileIDSampleRemovalNotice,
  useSmileIDSampleJobStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleTransientNotice,
  useSmileIDSampleStrings,
} from '@smileid/sample-ui';
import { useFocusEffect, useRouter } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { smileIDSampleStatusApi } from '../../src/status/use-smile-id-sample-status-api';
import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';
import { useSmileIDSampleNoticeStyle } from '../../src/use-smile-id-sample-notice-inset';
import { useSmileIDSampleSetSelectMode } from '../../src/use-smile-id-sample-select-mode';

export default function Verifications() {
  const strings = useSmileIDSampleStrings();
  const router = useRouter();
  const notice = useSmileIDSampleTransientNotice();
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const load = useSmileIDSampleJobStore((state) => state.load);
  const remove = useSmileIDSampleJobStore((state) => state.remove);
  const undoRemove = useSmileIDSampleJobStore((state) => state.undoRemove);
  const consumeRemoval = useSmileIDSampleJobStore((state) => state.consumeRemoval);
  const removals = useSmileIDSampleJobStore((state) => state.removals);
  // Read once rather than on every render: the day headers derive from the rows and this value, and
  // a clock read in render would recompute them on every pass and make the render impure.
  const [nowMillis] = useState(() => Date.now());
  const bottomInset = useSmileIDSampleListInset();
  const noticeStyle = useSmileIDSampleNoticeStyle(bottomInset);
  const setSelecting = useSmileIDSampleSetSelectMode();

  // No endpoint lists a partner's jobs, so the focused list asks about each processing row, and again while one still is.
  const refreshProcessing = useSmileIDSampleJobStore((state) => state.refreshProcessing);
  const liveSessionId = useSmileIDSampleSessionStore((state) => state.live?.id ?? null);
  useFocusEffect(
    useCallback(() => {
      let poll: ReturnType<typeof setTimeout> | undefined;
      let left = false;
      let attempt = 0;
      const check = async () => {
        const pending = await refreshProcessing(
          useSmileIDSampleSessionStore.getState().live,
          Date.now(),
          smileIDSampleStatusApi,
        );
        if (left || pending === 0) return;
        const wait = smileIDSampleProcessingPollDelayMillis(attempt++);
        if (wait !== null) poll = setTimeout(() => void check(), wait);
      };
      void check();
      return () => {
        left = true;
        clearTimeout(poll);
      };
      // The session id restarts the check: a newly scanned session can answer rows the last could not.
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [refreshProcessing, liveSessionId]),
  );

  // A tab stays mounted when you leave it, so select mode left on would hide the bar on every tab.
  useFocusEffect(useCallback(() => () => setSelecting(false), [setSelecting]));
  const { show } = notice;

  useEffect(() => {
    void load();
  }, [load]);

  // Consumed on sight, so returning to the list cannot replay a confirmation already acted on.
  useEffect(() => {
    if (removals.length === 0) return;
    const count = consumeRemoval();
    if (count === null) return;
    show({ ...smileIDSampleRemovalNotice(count, strings), onAction: () => void undoRemove() });
  }, [removals, consumeRemoval, undoRemove, show, strings]);

  return (
    <View style={styles.host}>
      <VerificationsScreen
        state={{ jobs, nowMillis }}
        onJobPress={(job) => router.push(`/verifications/${job.id}`)}
        // The write outlives this screen: a removal must land even if the reader navigates at once.
        onRemove={(ids) => void remove(ids)}
        onSelectingChange={setSelecting}
        bottomInset={bottomInset}
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={noticeStyle} />
    </View>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1 },
});
