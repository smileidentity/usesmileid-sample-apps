import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { steps, validate } from '@smileid/njia';

import {
  smileIDSampleFacts,
  smileIDSampleNjiaGraph,
  smileIDSampleSteps,
} from '../src/navigation/use-smile-id-sample-njia';

const specGraph = (): string => readFileSync(join(__dirname, '../../../spec/njia-graph.json'), 'utf8');

describe('the njia graph', () => {
  const graph = smileIDSampleNjiaGraph();

  it('is valid', () => {
    expect(validate(graph)).toEqual([]);
  });

  it('names every kind the app knows as a step, once', () => {
    const kinds = steps(graph).map((step) => step.kind);
    expect([...kinds].sort()).toEqual([...smileIDSampleSteps].sort());
  });

  it('reads every fact the app knows in some skipWhen', () => {
    const conditions = [...graph.nodes, ...steps(graph)].flatMap((node) =>
      node.skipWhen === undefined ? [] : [node.skipWhen],
    );
    const read = new Set(conditions.flatMap((condition) => [...condition.allOf, ...condition.noneOf]));
    expect([...read].sort()).toEqual([...smileIDSampleFacts].sort());
  });

  it('bundles the spec graph', () => {
    expect(readFileSync(join(__dirname, '../assets/njia-graph.json'), 'utf8')).toBe(specGraph());
  });

  it('refuses a kind the app does not know', () => {
    const json = JSON.parse(specGraph()) as { nodes: { kind?: string }[] };
    const unknown = { ...json, nodes: [...json.nodes.slice(1), { step: 'stray', kind: 'stray' }] };
    expect(() => smileIDSampleNjiaGraph(unknown)).toThrow();
  });
});
