import {
  NjiaEngine,
  NjiaIntents,
  isDone,
  navigatorFor,
  select,
  stepOf,
  type NjiaEntry,
  type NjiaNativeModule,
  type NjiaState,
  type NjiaTransition,
} from '@smileid/njia';
import type { NjiaStepScope } from '@smileid/njia/host';
import type { UseSmileIDSampleProduct } from '@smileid/sample-ui';
import { createContext, use } from 'react';

import {
  smileIDSampleFacts,
  smileIDSampleNjiaCodec,
  type UseSmileIDSampleFact,
  type UseSmileIDSampleGraph,
  type UseSmileIDSampleStep,
} from './use-smile-id-sample-njia';

/// The shell's engine, over the app's own step kinds and facts.
export type UseSmileIDSampleEngine = NjiaEngine<UseSmileIDSampleStep, UseSmileIDSampleFact>;

/// What each of the app's steps sees of the flow.
export type UseSmileIDSampleStepScope = NjiaStepScope<UseSmileIDSampleStep, UseSmileIDSampleFact>;

/// Where a run starts: the facts it runs under and the step a product tap goes to.
export type UseSmileIDSampleRunEntry = {
  readonly facts: ReadonlySet<UseSmileIDSampleFact>;
  readonly step: string;
};

/// The runs, whose entries a link to another tab never parks.
const runKinds: ReadonlySet<UseSmileIDSampleStep> = new Set(['sdkFlow', 'sdkFlowFullScreen']);

/// The wizard's step kinds, which a run's product is read through.
const wizardKinds: ReadonlySet<UseSmileIDSampleStep> = new Set([
  'consentDetailsForm',
  'authUserId',
  'idDetailsForm',
  'sdkFlow',
  'sdkFlowFullScreen',
]);

/// Holds the shell's engine and tells its subscribers whenever the flow moves or is replaced.
export class UseSmileIDSampleNavigationModel {
  private current: UseSmileIDSampleEngine | null = null;
  private replaced = 0;
  private readonly subscribers = new Set<() => void>();
  private readonly moved = (_: NjiaTransition<UseSmileIDSampleFact>) => this.notify();

  /// A model for `graph` whose engines run on `module`: njia's native core unless a test hands in its reference.
  constructor(
    readonly graph: UseSmileIDSampleGraph,
    private readonly module?: NjiaNativeModule,
  ) {}

  /// The flow on screen, null until `start` has run.
  get engine(): UseSmileIDSampleEngine | null {
    return this.current;
  }

  /// Counts the flows this model has drawn, so a host keyed by it starts afresh on a replaced flow.
  get generation(): number {
    return this.replaced;
  }

  /// Starts at `link` under `facts` when the graph opens it, else on the products tab.
  start(link?: string, facts: ReadonlySet<UseSmileIDSampleFact> = new Set()): void {
    const opened = link === undefined ? undefined : this.openLink(link, facts);
    this.replace(opened ?? this.fresh());
  }

  /// Opens `link` under `facts` as a new flow, keeping the other tabs' stacks; a link the graph refuses leaves the current one.
  open(link: string, facts: ReadonlySet<UseSmileIDSampleFact>): boolean {
    const opened = this.openLink(link, facts);
    if (opened === undefined) return false;
    this.replace(this.current === null ? opened : this.keepingOtherTabs(this.current.state, opened));
    return true;
  }

  /// A fresh flow on the products tab.
  restart(): void {
    this.replace(this.fresh());
  }

  /// Calls `listener` on every move or replacement, until the returned function is called.
  subscribe = (listener: () => void): (() => void) => {
    this.subscribers.add(listener);
    return () => this.subscribers.delete(listener);
  };

  /// Whether the flow on screen has finished, which back from the products root does.
  get done(): boolean {
    return this.current !== null && isDone(this.current.state);
  }

  /// Releases the engine on screen.
  dispose(): void {
    this.current?.removeListener(this.moved);
    this.current?.dispose();
    this.current = null;
  }

  private fresh(): UseSmileIDSampleEngine {
    return NjiaEngine.start(smileIDSampleNjiaCodec, this.graph, { module: this.module });
  }

  private openLink(link: string, facts: ReadonlySet<UseSmileIDSampleFact>): UseSmileIDSampleEngine | undefined {
    return NjiaEngine.openLink(smileIDSampleNjiaCodec, this.graph, link, { facts, module: this.module });
  }

  /// `next`, with the stacks `previous` held on the tabs the link didn't open, up to a run.
  private keepingOtherTabs(
    previous: NjiaState<UseSmileIDSampleFact>,
    next: UseSmileIDSampleEngine,
  ): UseSmileIDSampleEngine {
    const previousTab = previous.entries[0]?.step;
    const openedTab = next.state.entries[0]?.step;
    if (previousTab === undefined || openedTab === undefined) return next;
    const stacks: Record<string, readonly NjiaEntry[]> = { ...previous.parked, [previousTab]: previous.entries.slice(1) };
    const parked: Record<string, readonly NjiaEntry[]> = { ...next.state.parked };
    let nextId = next.state.nextId;
    for (const [tab, entries] of Object.entries(stacks)) {
      if (tab === openedTab || tab in parked) continue;
      // Up to a run, not past it: a parked run's entry takes a new id, so its result would find nothing to leave.
      const end = entries.findIndex((entry) => runKinds.has(stepOf(this.graph, entry).kind));
      const kept = end < 0 ? entries : entries.slice(0, end);
      if (kept.length === 0) continue;
      parked[tab] = kept.map((entry) => ({ ...entry, id: nextId++ }));
    }
    if (Object.keys(parked).length === Object.keys(next.state.parked ?? {}).length) return next;
    try {
      const merged = NjiaEngine.restore(
        smileIDSampleNjiaCodec,
        this.graph,
        { ...next.state, nextId, parked },
        { module: this.module },
      );
      next.dispose();
      return merged;
    } catch {
      return next;
    }
  }

  private replace(next: UseSmileIDSampleEngine): void {
    const previous = this.current;
    previous?.removeListener(this.moved);
    next.addListener(this.moved);
    this.current = next;
    this.replaced += 1;
    this.notify();
    previous?.dispose();
  }

  private notify(): void {
    for (const subscriber of this.subscribers) subscriber();
  }
}

/// Gives the steps the shell's model, so a step reaches the engine for what its own navigator can't do.
export const UseSmileIDSampleNavigationContext = createContext<UseSmileIDSampleNavigationModel | null>(null);

/// The flow on screen; a step is only ever drawn once it has started.
export const useSmileIDSampleEngine = (): UseSmileIDSampleEngine => {
  const engine = use(UseSmileIDSampleNavigationContext)?.engine;
  if (engine == null) throw new Error('a step drew outside the shell, or before its flow started');
  return engine;
};

/// The entry a run started at: the nearest wizard entry at or below `entry` that carries the product.
export const smileIDSampleRunStart = (engine: UseSmileIDSampleEngine, entry: NjiaEntry): NjiaEntry | undefined => {
  const entries = engine.state.entries;
  const at = entries.findIndex((candidate) => candidate.id === entry.id);
  if (at < 0) return undefined;
  return entries
    .slice(0, at + 1)
    .filter((candidate) => candidate.arg !== undefined && wizardKinds.has(stepOf(engine.graph, candidate).kind))
    .at(-1);
};

/// The product the run `entry` belongs to, read from the run's first entry.
export const smileIDSampleRunProductId = (engine: UseSmileIDSampleEngine, entry: NjiaEntry): string | undefined =>
  smileIDSampleRunStart(engine, entry)?.arg;

/// Starts a run of `product` from `from`, in place of `replace` if given, under the run's facts alone.
export const smileIDSampleStartRun = (
  engine: UseSmileIDSampleEngine,
  from: NjiaEntry,
  product: UseSmileIDSampleProduct,
  run: UseSmileIDSampleRunEntry,
  replace?: number,
): void => {
  engine.send(
    NjiaIntents.facts(
      [...run.facts],
      smileIDSampleFacts.filter((fact) => !run.facts.has(fact)),
    ),
  );
  navigatorFor(engine, from).go(run.step, product.id, replace);
};

/// Leaves the run `entry` belongs to by going to `step` in its place, with `arg`.
export const smileIDSampleLeaveRun = (
  engine: UseSmileIDSampleEngine,
  entry: NjiaEntry,
  step: UseSmileIDSampleStep,
  arg?: string,
): void => {
  navigatorFor(engine, entry).go(step, arg, (smileIDSampleRunStart(engine, entry) ?? entry).id);
};

/// Back to the products tab's root, which leaves a run however deep it went.
export const smileIDSampleLeaveToProducts = (engine: UseSmileIDSampleEngine): void => {
  select(engine, 'products');
};
