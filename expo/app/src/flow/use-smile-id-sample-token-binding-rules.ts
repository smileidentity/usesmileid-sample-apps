import {
  smileIDSampleLiveSession,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleTokenBindings,
  type UseSmileIDSampleTokenSession,
} from '@smileid/sample-ui';

import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// The two refresh scenarios, which keep the fixture tokens.
export const smileIDSampleStartsExpired = (scenario: string): boolean =>
  scenario === 'expiredToken' || scenario === 'badRefresh';

/// The live-session rule in one place.
const smileIDSampleLiveSessionFor = (
  session: UseSmileIDSampleTokenSession | null,
  scenario: string,
  nowMillis: number,
): UseSmileIDSampleTokenSession | null =>
  smileIDSampleStartsExpired(scenario) ? null : smileIDSampleLiveSession({ live: session }, nowMillis);

/// The bindings a run starting now may read, from the clock rather than the last tick.
export const smileIDSampleLiveBindingsNow = (scenario: string): UseSmileIDSampleTokenBindings | null =>
  smileIDSampleLiveSessionFor(useSmileIDSampleSessionStore.getState().live, scenario, Date.now())?.bindings ??
  null;

/// The bindings a form renders from, re-read on each tick.
export const useSmileIDSampleLiveBindings = (): UseSmileIDSampleTokenBindings | null => {
  const { scenario } = useLaunchArgs();
  const live = useSmileIDSampleSessionStore((state) => state.live);
  const nowMillis = useSmileIDSampleSessionStore((state) => state.nowMillis);
  return smileIDSampleLiveSessionFor(live, scenario, nowMillis)?.bindings ?? null;
};
