import { VerificationsScreen, useSmileIDSampleJobStore } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';
import { useEffect, useState } from 'react';

export default function Verifications() {
  const router = useRouter();
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const load = useSmileIDSampleJobStore((state) => state.load);
  const remove = useSmileIDSampleJobStore((state) => state.remove);
  // Read once rather than on every render: the day headers derive from the rows and this value, and
  // a clock read in render would recompute them on every pass and make the render impure.
  const [nowMillis] = useState(() => Date.now());

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <VerificationsScreen
      state={{ jobs, nowMillis }}
      onJobPress={(job) => router.push(`/verifications/${job.id}`)}
      // The write outlives this screen: a removal must land even if the reader navigates at once.
      onRemove={(ids) => void remove(ids)}
    />
  );
}
