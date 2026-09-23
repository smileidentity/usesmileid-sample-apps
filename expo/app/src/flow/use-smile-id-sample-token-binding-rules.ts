import {
  smileIDSampleLiveSession,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleTokenBindings,
  type UseSmileIDSampleTokenSession,
  type UseSmileIDSampleUserDetailsRequirement,
} from '@smileid/sample-ui';
import type { UseSmileIDValidationException, ValidationState } from '@smileid/usesmileid';

import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// The two scenarios that are about refresh, which a scanned token has no journey for, so they keep the fixtures.
export const smileIDSampleStartsExpired = (scenario: string): boolean =>
  scenario === 'expiredToken' || scenario === 'badRefresh';

/// The live-session rule in one place, so nothing disagrees about whether a token is live.
export const smileIDSampleLiveSessionFor = (
  session: UseSmileIDSampleTokenSession | null,
  scenario: string,
  nowMillis: number,
): UseSmileIDSampleTokenSession | null =>
  smileIDSampleStartsExpired(scenario) ? null : smileIDSampleLiveSession({ live: session }, nowMillis);

/// The bindings a run starting now may read: the clock is read here, never the last tick.
export const smileIDSampleLiveBindingsNow = (scenario: string): UseSmileIDSampleTokenBindings | null =>
  smileIDSampleLiveSessionFor(useSmileIDSampleSessionStore.getState().live, scenario, Date.now())?.bindings ??
  null;

/// The bindings a form renders from, through the same rule; the tick re-renders it when the session lapses.
export const useSmileIDSampleLiveBindings = (): UseSmileIDSampleTokenBindings | null => {
  const { scenario } = useLaunchArgs();
  const live = useSmileIDSampleSessionStore((state) => state.live);
  const nowMillis = useSmileIDSampleSessionStore((state) => state.nowMillis);
  return smileIDSampleLiveSessionFor(live, scenario, nowMillis)?.bindings ?? null;
};

/// Drops the issues the token already answers; every other rule the SDK applies still stands.
export const smileIDSampleMinusRequirement = (
  state: ValidationState,
  requirement: UseSmileIDSampleUserDetailsRequirement,
): ValidationState => {
  if (state.valid) return state;
  const outstanding = state.issues.filter((issue) => !covers(requirement, issue));
  return outstanding.length === 0 ? { valid: true } : { ...state, issues: outstanding };
};

const covers = (requirement: UseSmileIDSampleUserDetailsRequirement, issue: UseSmileIDValidationException): boolean => {
  const details = issue.errorDetails as { fieldName?: unknown; reason?: unknown } | undefined;
  switch (details?.fieldName) {
    case 'userDetails.givenNames':
      return !requirement.firstName;
    case 'userDetails.lastName':
      return !requirement.lastName;
    // The contact rule is reported against the object, so its reason is what identifies it.
    case 'userDetails':
      return !requirement.contact && String(details.reason).toLowerCase().includes('email');
    default:
      return false;
  }
};
