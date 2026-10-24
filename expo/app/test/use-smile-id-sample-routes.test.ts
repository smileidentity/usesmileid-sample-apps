import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { NjiaEngine, step, steps, stepOf, top } from '@smileid/njia';
import { ReferenceNjiaNative } from '@smileid/njia-testing';
import type { UseSmileIDSampleFlowRoute } from '@smileid/sample-ui';

import { smileIDSampleLinkOf } from '../src/navigation/use-smile-id-sample-deep-links';
import { smileIDSampleNjiaCodec, type UseSmileIDSampleFact } from '../src/navigation/use-smile-id-sample-njia';
import { smileIDSampleSteps } from '../src/navigation/use-smile-id-sample-steps';
import { smileIDSampleTestGraph as graph } from './support/use-smile-id-sample-test-njia';

/// One row of `spec/routes.json`, whose links this file asserts through `spec/njia-graph.json`: a renamed path or step otherwise kills a link silently.
type Route = {
  readonly id: string;
  readonly path: string;
  readonly presentation: string;
  readonly platform: Record<string, string>;
};

const routes = (
  JSON.parse(readFileSync(join(__dirname, '../../../spec/routes.json'), 'utf8')) as { routes: readonly Route[] }
).routes;

/// The route's path under this app's scheme, each parameter filled with a sample value.
const sampleUrl = (route: Route) =>
  `usesmileid-sample-expo://${route.path.slice(1).replace(/:([A-Za-z][A-Za-z0-9]*)/g, 'sample-$1')}`;

/// Every fact a link might need: the run's forms all shown, on `route`.
const factsFor = (route: UseSmileIDSampleFlowRoute): UseSmileIDSampleFact[] => [
  'needsUserId',
  'needsIdDetails',
  ...(route === 'fullscreen' ? (['fullScreenRun'] as const) : []),
];

describe('the route table', () => {
  it('lists routes, so no assertion below passes on nothing', () => {
    expect(routes.length).toBeGreaterThan(0);
  });

  it.each(routes)('binds $id to the graph step the expo column names, linked at its path', (route) => {
    const graphStep = step(graph, route.id);
    expect(graphStep?.link).toBe(route.path.slice(1));
    expect(route.platform.expo!.split(' | ')[0]).toBe(`UseSmileIDSampleStep.${graphStep!.kind}`);
  });

  it("names every step by its kind's name", () => {
    for (const graphStep of steps(graph)) expect(graphStep.id).toBe(graphStep.kind);
  });

  it.each(routes)('draws $id as a sheet exactly when the spec calls it one', (route) => {
    expect(step(graph, route.id)!.presentation === 'sheet').toBe(route.presentation.endsWith('Sheet'));
  });

  it('draws every kind in the graph', () => {
    expect(smileIDSampleSteps.missing(graph)).toEqual([]);
  });
});

describe('every spec link', () => {
  it.each(routes)('opens $id at its own step', (route) => {
    const link = smileIDSampleLinkOf(sampleUrl(route));
    expect(link).not.toBeNull();
    const asked = link!.route ?? 'shell';
    const engine = NjiaEngine.openLink(smileIDSampleNjiaCodec, graph, link!.path, {
      facts: factsFor(asked),
      module: new ReferenceNjiaNative().nativeModule,
    });
    expect(engine).toBeDefined();
    expect(stepOf(graph, top(engine!.state)!).id).toBe(
      route.id === 'sdkFlow' && asked === 'fullscreen' ? 'sdkFlowFullScreen' : route.id,
    );
    engine!.dispose();
  });

  it('runs full screen unless the run link asks for the shell', () => {
    expect(smileIDSampleLinkOf('usesmileid-sample-expo://flow/biometricKyc/run')).toEqual({
      path: 'flow/biometricKyc/run-fullscreen',
      route: 'fullscreen',
    });
    expect(smileIDSampleLinkOf('usesmileid-sample-expo://flow/biometricKyc/run?route=shell')).toEqual({
      path: 'flow/biometricKyc/run',
      route: 'shell',
    });
  });

  it('reads no link from a launch from the icon or a bare scheme', () => {
    expect(smileIDSampleLinkOf(null)).toBeNull();
    expect(smileIDSampleLinkOf('usesmileid-sample-expo://')).toBeNull();
    expect(smileIDSampleLinkOf('usesmileid-sample-expo://?seedJobs=true')).toBeNull();
  });
});
