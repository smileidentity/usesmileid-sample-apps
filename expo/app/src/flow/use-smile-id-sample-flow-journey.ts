import {
  smileIDSampleLiveSession,
  smileIDSampleRequirementSatisfied,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleFlowRoute,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleTokenBindings,
} from '@smileid/sample-ui';
import type { Href } from 'expo-router';

import { smileIDSampleFlowPlan } from './use-smile-id-sample-flow-plan';
import { smileIDSampleLiveBindingsNow } from './use-smile-id-sample-token-binding-rules';

/// A product tap: the scanner first when no live session backs the run, since every run submits under a token.
export const smileIDSampleEntryFor = (
  product: UseSmileIDSampleProduct,
  route: UseSmileIDSampleFlowRoute,
  scenario: string,
): Href => {
  const store = useSmileIDSampleSessionStore.getState();
  const live = smileIDSampleLiveSession(store, Date.now());
  store.recordRunPartner(live?.partnerId ?? null);
  if (live === null) {
    store.sendRun({ productId: product.id, route, resumeAt: 'firstStep' });
    return '/token/scan';
  }
  return smileIDSampleFirstStepFor(product, smileIDSampleLiveBindingsNow(scenario));
};

/// What follows user details, shared with that form's Continue.
export const smileIDSampleStepAfterUserDetails = (
  product: UseSmileIDSampleProduct,
  bindings: UseSmileIDSampleTokenBindings | null,
): Href =>
  smileIDSampleFlowPlan(bindings, product).showIdDetailsForm
    ? `/flow/${product.id}/id-details`
    : `/flow/${product.id}/run`;

/// A product's first step, past the form when the token binds all it collects.
export const smileIDSampleFirstStepFor = (
  product: UseSmileIDSampleProduct,
  bindings: UseSmileIDSampleTokenBindings | null,
): Href =>
  smileIDSampleRequirementSatisfied(smileIDSampleFlowPlan(bindings, product).userDetailsGap)
    ? smileIDSampleStepAfterUserDetails(product, bindings)
    : `/flow/${product.id}/details`;
