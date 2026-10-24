import { holdsFor, steps } from '@smileid/njia';
import type { UseSmileIDSampleFlowRoute, UseSmileIDSampleProduct } from '@smileid/sample-ui';

import type { UseSmileIDSampleFact, UseSmileIDSampleGraph, UseSmileIDSampleStep } from './use-smile-id-sample-njia';

/// The facts a run of `product` starts with, which the graph's `skipWhen` reads to skip a form.
export const smileIDSampleRunFacts = (
  product: UseSmileIDSampleProduct,
  { bindsIdDetails, route }: { bindsIdDetails: boolean; route: UseSmileIDSampleFlowRoute },
): ReadonlySet<UseSmileIDSampleFact> =>
  new Set<UseSmileIDSampleFact>([
    ...(product.id === 'smartSelfieAuth' ? (['needsUserId'] as const) : []),
    ...(product.needsIdDetails && !bindsIdDetails ? (['needsIdDetails'] as const) : []),
    ...(route === 'fullscreen' ? (['fullScreenRun'] as const) : []),
  ]);

/// The wizard's steps in the order `next` walks them: the consent form, the two optional forms and the run's two forms.
const wizard: readonly UseSmileIDSampleStep[] = [
  'consentDetailsForm',
  'authUserId',
  'idDetailsForm',
  'sdkFlow',
  'sdkFlowFullScreen',
];

/// Where a product tap goes: the consent form unless the token binds user details, else the first wizard step `facts` leave.
export const smileIDSampleFirstStep = (
  graph: UseSmileIDSampleGraph,
  facts: ReadonlySet<UseSmileIDSampleFact>,
  { bindsUserDetails }: { bindsUserDetails: boolean },
): string => {
  const all = steps(graph);
  const first = wizard
    .slice(bindsUserDetails ? 1 : 0)
    .map((kind) => all.find((step) => step.kind === kind))
    .find((step) => step !== undefined && (step.skipWhen === undefined || !holdsFor(step.skipWhen, facts)));
  if (first === undefined) throw new Error('the graph has no wizard step these facts leave');
  return first.id;
};
