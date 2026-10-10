import {
  AuthUserIdScreen,
  smileIDSampleProductFrom,
  smileIDSamplePreviousAuthUserIds,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleJobStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect } from 'react';

import { smileIDSampleEntryFor } from '../../../src/flow/use-smile-id-sample-flow-journey';
import { useLaunchArgs } from '../../../src/use-smile-id-sample-launch';
import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';

/// SmartSelfie Authentication's user ID, typed or picked from runs that enrolled one; the run never makes one up.
export default function AuthUserId() {
  const router = useRouter();
  const back = useSmileIDSampleBack('/products');
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const { route, scenario } = useLaunchArgs();
  const profile = useSmileIDSampleActiveProfile();
  const userId = useSmileIDSampleFormsStore((state) => state.authUserId);
  const setAuthUserId = useSmileIDSampleFormsStore((state) => state.setAuthUserId);
  const startRun = useSmileIDSampleFormsStore((state) => state.startRun);
  const jobs = useSmileIDSampleJobStore((state) => state.jobs);
  const load = useSmileIDSampleJobStore((state) => state.load);

  // A cold link lands here without the list, which is otherwise the screen that loads the store.
  useEffect(() => {
    if (jobs === null) void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <AuthUserIdScreen
      state={{ userId, previousUserIds: smileIDSamplePreviousAuthUserIds(jobs ?? []) }}
      onUserIdChange={setAuthUserId}
      onRegister={() => {
        const enrollment = smileIDSampleProductFrom('smartSelfieEnrollment');
        if (enrollment === null) return;
        startRun(profile);
        router.replace(smileIDSampleEntryFor(enrollment, route, scenario));
      }}
      onBack={() => back()}
      onContinue={() => router.push(`/flow/${productId}/run`)}
    />
  );
}
