import { stepOf, top, type NjiaEntry } from '@smileid/njia';
import { FakeNjiaNavigator, ReferenceNjiaNative } from '@smileid/njia-testing';

import {
  type UseSmileIDSampleEngine,
  type UseSmileIDSampleNavigationModel,
  type UseSmileIDSampleStepScope,
} from '../../src/navigation/use-smile-id-sample-navigation';
import { smileIDSampleNjiaGraph, type UseSmileIDSampleStep } from '../../src/navigation/use-smile-id-sample-njia';
import { smileIDSampleNavigation, smileIDSampleResetNavigation } from '../../src/navigation/use-smile-id-sample-shell';

/// The spec's graph, as the app decodes it.
export const smileIDSampleTestGraph = smileIDSampleNjiaGraph();

/// A fresh navigation model whose engines run njia's reducer in JavaScript, so tests route the real graph.
export const smileIDSampleReferenceNavigation = (): {
  reference: ReferenceNjiaNative;
  model: UseSmileIDSampleNavigationModel;
} => {
  smileIDSampleResetNavigation();
  const reference = new ReferenceNjiaNative();
  return { reference, model: smileIDSampleNavigation(reference.nativeModule) };
};

/// A step's scope with a navigator that records its calls instead of moving any flow.
export const smileIDSampleFakeScope = (
  step: UseSmileIDSampleStep,
  options: { arg?: string; id?: number } = {},
): { scope: UseSmileIDSampleStepScope; navigator: FakeNjiaNavigator } => {
  const entry: NjiaEntry = { id: options.id ?? 1, step, visit: 0, ...(options.arg === undefined ? {} : { arg: options.arg }) };
  const navigator = new FakeNjiaNavigator(entry);
  const graphStep = stepOf(smileIDSampleTestGraph, entry);
  const scope: UseSmileIDSampleStepScope = {
    entry,
    step: graphStep,
    navigator,
    isTop: true,
    dependency: () => {
      throw new Error('the app provides no dependencies');
    },
    retained: (_key, make) => make(),
  };
  return { scope, navigator };
};

/// The kinds of the flow's stack, bottom first, which is what a user could go back through.
export const smileIDSampleStackKinds = (engine: UseSmileIDSampleEngine): UseSmileIDSampleStep[] =>
  engine.state.entries.map((entry) => stepOf(engine.graph, entry).kind);

/// The kind of the step on top of the flow.
export const smileIDSampleTopKind = (engine: UseSmileIDSampleEngine): UseSmileIDSampleStep | undefined => {
  const entry = top(engine.state);
  return entry === undefined ? undefined : stepOf(engine.graph, entry).kind;
};
