import {
  smileIDSampleFlowPlan,
  smileIDSampleLiveSession,
  smileIDSampleRequirementSatisfied,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleTokenBindings,
} from '@smileid/sample-ui';
import type { Href } from 'expo-router';

import { smileIDSampleStartsExpired } from './use-smile-id-sample-flow-launch-snapshot';
import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// The bindings a form may read, through the same live-session rule the gate uses, so a skipped form never bounces back.
export const useSmileIDSampleLiveBindings = (): UseSmileIDSampleTokenBindings | null => {
  const { scenario } = useLaunchArgs();
  const bindings = useSmileIDSampleSessionStore(
    (state) => smileIDSampleLiveSession(state, state.nowMillis)?.bindings ?? null,
  );
  return smileIDSampleStartsExpired(scenario) ? null : bindings;
};

/// What follows user details, shared with that form's own Continue so the two routes cannot drift.
export const smileIDSampleStepAfterUserDetails = (
  product: UseSmileIDSampleProduct,
  bindings: UseSmileIDSampleTokenBindings | null,
): Href =>
  smileIDSampleFlowPlan(bindings, product).showIdDetailsForm
    ? `/flow/${product.id}/id-details`
    : `/flow/${product.id}/run`;

/// A product's first step: past the form when the token binds everything it would collect.
export const smileIDSampleFirstStepFor = (
  product: UseSmileIDSampleProduct,
  bindings: UseSmileIDSampleTokenBindings | null,
): Href =>
  smileIDSampleRequirementSatisfied(smileIDSampleFlowPlan(bindings, product).userDetailsGap)
    ? smileIDSampleStepAfterUserDetails(product, bindings)
    : `/flow/${product.id}/details`;
