import {
  smileIDSampleBindsIdDetails,
  smileIDSampleLiveSession,
  smileIDSampleProducts,
  smileIDSampleRequirementSatisfied,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleFlowRoute,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleTokenBindings,
} from '@smileid/sample-ui';

import { smileIDSampleLinkProductId, type UseSmileIDSampleLink } from '../navigation/use-smile-id-sample-deep-links';
import type { UseSmileIDSampleRunEntry } from '../navigation/use-smile-id-sample-navigation';
import type { UseSmileIDSampleFact, UseSmileIDSampleGraph } from '../navigation/use-smile-id-sample-njia';
import { smileIDSampleFirstStep, smileIDSampleRunFacts } from '../navigation/use-smile-id-sample-njia-facts';
import { smileIDSampleFlowPlan } from './use-smile-id-sample-flow-plan';
import { smileIDSampleLiveBindingsNow } from './use-smile-id-sample-token-binding-rules';

/// A product tap's run, or null when no live session backs it and the scanner comes first, since every run submits under a token.
export const smileIDSampleEntryFor = (
  graph: UseSmileIDSampleGraph,
  product: UseSmileIDSampleProduct,
  route: UseSmileIDSampleFlowRoute,
  scenario: string,
): UseSmileIDSampleRunEntry | null => {
  const store = useSmileIDSampleSessionStore.getState();
  const live = smileIDSampleLiveSession(store, Date.now());
  store.recordRunPartner(live?.partnerId ?? null);
  if (live === null) {
    store.sendRun({ productId: product.id, route, resumeAt: 'firstStep' });
    return null;
  }
  return smileIDSampleRunEntryFor(graph, product, route, smileIDSampleLiveBindingsNow(scenario));
};

/// Where `product` starts on `route` under `bindings`: a form is skipped only when the token already carries all of it.
export const smileIDSampleRunEntryFor = (
  graph: UseSmileIDSampleGraph,
  product: UseSmileIDSampleProduct,
  route: UseSmileIDSampleFlowRoute,
  bindings: UseSmileIDSampleTokenBindings | null,
): UseSmileIDSampleRunEntry => {
  const facts = smileIDSampleRunFacts(product, { bindsIdDetails: smileIDSampleBindsIdDetails(bindings, product), route });
  const bindsUserDetails = smileIDSampleRequirementSatisfied(smileIDSampleFlowPlan(bindings, product).userDetailsGap);
  return { facts, step: smileIDSampleFirstStep(graph, facts, { bindsUserDetails }) };
};

/// Straight into the run on `route`, past every form, as an autostart or a resumed run goes.
export const smileIDSampleRunOnly = (
  product: UseSmileIDSampleProduct,
  route: UseSmileIDSampleFlowRoute,
  bindings: UseSmileIDSampleTokenBindings | null,
): UseSmileIDSampleRunEntry => ({
  facts: smileIDSampleRunFacts(product, { bindsIdDetails: smileIDSampleBindsIdDetails(bindings, product), route }),
  step: route === 'fullscreen' ? 'sdkFlowFullScreen' : 'sdkFlow',
});

/// The facts a link's run starts with: its product's, on the route it asked for, or the launch's.
export const smileIDSampleLinkFacts = (
  link: UseSmileIDSampleLink,
  launchRoute: UseSmileIDSampleFlowRoute,
  bindings: UseSmileIDSampleTokenBindings | null,
): ReadonlySet<UseSmileIDSampleFact> => {
  const product = smileIDSampleProductOf(smileIDSampleLinkProductId(link));
  if (product === undefined) return new Set();
  return smileIDSampleRunFacts(product, {
    bindsIdDetails: smileIDSampleBindsIdDetails(bindings, product),
    route: link.route ?? launchRoute,
  });
};

/// The product with `id`, or undefined for one this build does not know.
export const smileIDSampleProductOf = (id: string | undefined): UseSmileIDSampleProduct | undefined =>
  smileIDSampleProducts.find((product) => product.id === id);
