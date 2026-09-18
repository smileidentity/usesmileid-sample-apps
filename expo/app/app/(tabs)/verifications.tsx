import {
  UseSmileIDSampleTransientNoticeHost,
  VerificationsScreen,
  smileIDSampleRemovalNotice,
  useSmileIDSampleJobStore,
  useSmileIDSampleTransientNotice,
} from '@smileid/sample-ui';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';

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
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={styles.notice} />
    </View>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1 },
  // Clears the tab bar, which this route sits inside and the profiles list does not.
  notice: { bottom: 88, paddingHorizontal: 16, position: 'absolute' },
});
