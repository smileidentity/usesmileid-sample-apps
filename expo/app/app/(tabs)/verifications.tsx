import {
  UseSmileIDSampleTransientNoticeHost,
  VerificationsScreen,
  smileIDSampleRemovalNotice,
  useSmileIDSampleJobStore,
  useSmileIDSampleTransientNotice,
} from '@smileid/sample-ui';
import { useFocusEffect, useRouter } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';
import { useSmileIDSampleNoticeStyle } from '../../src/use-smile-id-sample-notice-inset';
import { useSmileIDSampleSetSelectMode } from '../../src/use-smile-id-sample-select-mode';

export default function Verifications() {
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
  // The bar it clears is measured, so this route's notice rides the same reserve the list does.
  const noticeStyle = useSmileIDSampleNoticeStyle(bottomInset);
  const setSelecting = useSmileIDSampleSetSelectMode();

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
    show({ ...smileIDSampleRemovalNotice(count), onAction: () => void undoRemove() });
  }, [removals, consumeRemoval, undoRemove, show]);

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
