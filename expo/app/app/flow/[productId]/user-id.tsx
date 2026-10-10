import {
  AuthUserIdScreen,
  smileIDSampleProductFrom,
  smileIDSamplePreviousAuthUserIds,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleJobStore,
  smileIDSampleLiveSession,
  useSmileIDSampleSessionStore,
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
  const live = useSmileIDSampleSessionStore((state) => smileIDSampleLiveSession(state, state.nowMillis));
  const load = useSmileIDSampleJobStore((state) => state.load);

  // A cold link lands here without the list, which is otherwise the screen that loads the store.
  useEffect(() => {
    if (jobs === null) void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <AuthUserIdScreen
      // A user is enrolled under one partner in one environment, so another's IDs would authenticate nobody.
      state={{
        userId,
        previousUserIds: smileIDSamplePreviousAuthUserIds(jobs ?? [], live?.partnerId ?? null, live?.environment !== 'production'),
      }}
      onUserIdChange={setAuthUserId}
      onRegister={() => {
        const enrollment = smileIDSampleProductFrom('smartSelfieEnrollment');
        if (enrollment === null) return;
        startRun(profile);
        router.replace(smileIDSampleEntryFor(enrollment, route, scenario));
      }}
      onBack={() => back()}
      // Navigate, not push: a second quick tap must not mount a second run.
      onContinue={() => router.navigate(`/flow/${productId}/run`)}
    />
  );
}
