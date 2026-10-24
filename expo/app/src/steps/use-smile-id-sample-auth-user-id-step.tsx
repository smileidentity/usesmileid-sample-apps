import {
  AuthUserIdScreen,
  smileIDSampleProductFrom,
  smileIDSamplePreviousAuthUsers,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleJobStore,
  smileIDSampleLiveSession,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { useEffect } from 'react';

import { smileIDSampleEntryFor } from '../flow/use-smile-id-sample-flow-journey';
import {
  smileIDSampleLeaveRun,
  smileIDSampleRunStart,
  smileIDSampleStartRun,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// SmartSelfie Authentication's user ID, typed or picked from runs that enrolled one; the run never makes one up.
export const UseSmileIDSampleAuthUserIdStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const engine = useSmileIDSampleEngine();
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
        previousUsers: smileIDSamplePreviousAuthUsers(jobs ?? [], live?.partnerId ?? null, live?.environment !== 'production'),
      }}
      onUserIdChange={setAuthUserId}
      onRegister={() => {
        const enrollment = smileIDSampleProductFrom('smartSelfieEnrollment');
        if (enrollment === null) return;
        startRun(profile);
        // In this run's place, so back from enrollment doesn't return to the authentication it replaced.
        const run = smileIDSampleEntryFor(engine.graph, enrollment, route, scenario);
        if (run === null) {
          smileIDSampleLeaveRun(engine, scope.entry, 'scanToken');
          return;
        }
        smileIDSampleStartRun(engine, scope.entry, enrollment, run, (smileIDSampleRunStart(engine, scope.entry) ?? scope.entry).id);
      }}
      onBack={() => scope.navigator.back()}
      // A second quick tap is stale: the navigator speaks only for this entry, which the first tap covered.
      onContinue={() => scope.navigator.next()}
    />
  );
};
