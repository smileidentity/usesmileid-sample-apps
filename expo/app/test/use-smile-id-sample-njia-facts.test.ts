import { navigatorFor, NjiaEngine, stepOf, top } from '@smileid/njia';
import { ReferenceNjiaNative } from '@smileid/njia-testing';
import {
  smileIDSampleFlowRoutes,
  smileIDSampleProducts,
  type UseSmileIDSampleFlowRoute,
  type UseSmileIDSampleProduct,
} from '@smileid/sample-ui';

import {
  smileIDSampleNjiaCodec,
  smileIDSampleNjiaGraph,
  type UseSmileIDSampleStep,
} from '../src/navigation/use-smile-id-sample-njia';
import { smileIDSampleFirstStep, smileIDSampleRunFacts } from '../src/navigation/use-smile-id-sample-njia-facts';

/// The wizard has five steps, so a longer walk is a loop.
const runLength = 5;

const graph = smileIDSampleNjiaGraph();

/// The shell's journey rules: consent unless bound, the auth user ID, ID details unless bound, then the run.
const expected = (
  product: UseSmileIDSampleProduct,
  bindsUser: boolean,
  bindsId: boolean,
  route: UseSmileIDSampleFlowRoute,
): UseSmileIDSampleStep[] => [
  ...(bindsUser ? [] : (['consentDetailsForm'] as const)),
  ...(product.id === 'smartSelfieAuth'
    ? (['authUserId'] as const)
    : product.needsIdDetails && !bindsId
      ? (['idDetailsForm'] as const)
      : []),
  route === 'fullscreen' ? 'sdkFlowFullScreen' : 'sdkFlow',
];

/// A product tap from the products tab, then `next` from each form until the run is on top.
const walked = (
  product: UseSmileIDSampleProduct,
  bindsUser: boolean,
  bindsId: boolean,
  route: UseSmileIDSampleFlowRoute,
): UseSmileIDSampleStep[] => {
  const reference = new ReferenceNjiaNative();
  const facts = smileIDSampleRunFacts(product, { bindsIdDetails: bindsId, route });
  const engine = NjiaEngine.start(smileIDSampleNjiaCodec, graph, { facts, module: reference.nativeModule });
  const onTop = () => top(engine.state)!;
  navigatorFor(engine, onTop()).go(smileIDSampleFirstStep(graph, facts, { bindsUserDetails: bindsUser }), product.id);
  const kinds: UseSmileIDSampleStep[] = [];
  for (;;) {
    const kind = stepOf(graph, onTop()).kind;
    kinds.push(kind);
    if (kind === 'sdkFlow' || kind === 'sdkFlowFullScreen' || kinds.length > runLength) break;
    navigatorFor(engine, onTop()).next();
  }
  engine.dispose();
  expect(reference.allDisposed).toBe(true);
  return kinds;
};

const runs = smileIDSampleProducts.flatMap((product) =>
  [false, true].flatMap((bindsUser) =>
    [false, true].flatMap((bindsId) =>
      smileIDSampleFlowRoutes.map((route) => ({ product, bindsUser, bindsId, route })),
    ),
  ),
);

describe('a run on the njia graph', () => {
  it.each(runs)(
    '$product.id, binds user $bindsUser, id $bindsId, $route: walks the forms its token leaves, then its run',
    ({ product, bindsUser, bindsId, route }) => {
      expect(walked(product, bindsUser, bindsId, route)).toEqual(expected(product, bindsUser, bindsId, route));
    },
  );

  it('names only the facts a run needs', () => {
    const product = (id: string) => smileIDSampleProducts.find((candidate) => candidate.id === id)!;
    expect([...smileIDSampleRunFacts(product('smartSelfieEnrollment'), { bindsIdDetails: false, route: 'shell' })]).toEqual(
      [],
    );
    expect([...smileIDSampleRunFacts(product('smartSelfieAuth'), { bindsIdDetails: false, route: 'fullscreen' })]).toEqual([
      'needsUserId',
      'fullScreenRun',
    ]);
  });

  it('refuses a graph with no wizard step left', () => {
    const bare = { ...graph, nodes: graph.nodes.slice(0, 1) };
    expect(() => smileIDSampleFirstStep(bare, new Set(), { bindsUserDetails: true })).toThrow();
  });
});
