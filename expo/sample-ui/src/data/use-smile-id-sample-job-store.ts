import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import { smileIDSampleJobFixtures } from './use-smile-id-sample-job-fixtures';
import {
  smileIDSampleJobFrom,
  type UseSmileIDSampleJob,
} from '../model/use-smile-id-sample-job';
import type { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';
import type {
  UseSmileIDSampleJobStatusSource,
  UseSmileIDSampleStatusRefresh,
} from './use-smile-id-sample-job-status-source';

const STORAGE_KEY = 'sample.jobs.v3';

/// A live token session, as much of it as a refresh needs to decide whether it may ask.
export type UseSmileIDSampleRefreshSession = {
  readonly token: string;
  readonly partnerId: string | null;
  readonly expiresAtMillis: number;
};

type State = {
  /// Null until the first read finishes: "not loaded yet" is not "no verifications".
  readonly jobs: readonly UseSmileIDSampleJob[] | null;
  /// Batch sizes of removals, consumed exactly once by whoever renders the confirmation.
  readonly removals: readonly number[];
};

type Actions = {
  load: () => Promise<void>;
  add: (job: UseSmileIDSampleJob) => Promise<void>;
  remove: (ids: readonly string[]) => Promise<void>;
  undoRemove: () => Promise<void>;
  applyStatus: (
    jobId: string,
    status: UseSmileIDSampleStatus,
    message: string,
    httpStatus: number,
  ) => Promise<boolean>;
  refresh: (
    jobId: string,
    session: UseSmileIDSampleRefreshSession | null,
    nowMillis: number,
    source: UseSmileIDSampleJobStatusSource,
  ) => Promise<UseSmileIDSampleStatusRefresh | null>;
  find: (jobId: string) => UseSmileIDSampleJob | null;
  consumeRemoval: () => number | null;
  seedFixtures: (nowMillis: number) => Promise<void>;
  reset: () => void;
};

/// What the last remove took, so undo re-inserts rather than clearing a soft-delete column.
let lastRemoved: readonly UseSmileIDSampleJob[] = [];

/// In flight per job id, so the entry refresh and a pull cannot double-request the same row.
const inFlight = new Set<string>();

/// Newest first, which is also what makes undo restore its own order without recording one.
const ordered = (jobs: readonly UseSmileIDSampleJob[]) =>
  [...jobs].sort((a, b) => b.createdAtMillis - a.createdAtMillis);

const persist = async (jobs: readonly UseSmileIDSampleJob[]) => {
  await AsyncStorage.setItem(
    STORAGE_KEY,
    JSON.stringify(jobs.map((job) => ({ ...job, product: job.product.id }))),
  );
};

/// The submitted verifications, on disk: the SDK delivers a result once, and there is nowhere else to get it from.
export const useSmileIDSampleJobStore = create<State & Actions>((set, get) => ({
  jobs: null,
  removals: [],

  load: async () => {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (raw === null) {
      set({ jobs: [] });
      return;
    }
    let parsed: unknown = null;
    try {
      parsed = JSON.parse(raw);
    } catch {
      // A store that no longer parses reads as empty rather than taking the screen down with it.
      set({ jobs: [] });
      return;
    }
    const rows = Array.isArray(parsed) ? parsed : [];
    const jobs = rows
      .map((row) => smileIDSampleJobFrom(row as Record<string, unknown>))
      .filter((job): job is UseSmileIDSampleJob => job !== null);
    set({ jobs: ordered(jobs) });
  },

  /// A no-op on an id already stored, which is what makes a repeated result delivery harmless.
  add: async (job) => {
    const current = get().jobs ?? [];
    if (current.some((row) => row.id === job.id)) return;
    const next = ordered([...current, job]);
    set({ jobs: next });
    await persist(next);
  },

  remove: async (ids) => {
    if (ids.length === 0) return;
    const current = get().jobs ?? [];
    const taken = current.filter((row) => ids.includes(row.id));
    // Guarded on what the removal actually took, not on what it was asked for: an id with no row
    // would otherwise overwrite a batch that is still undoable and silently spend the undo.
    if (taken.length === 0) return;
    lastRemoved = taken;
    const next = current.filter((row) => !ids.includes(row.id));
    set((state) => ({ jobs: next, removals: [...state.removals, taken.length] }));
    await persist(next);
  },

  /// Re-inserts the batch the last remove took, and is a no-op with nothing pending.
  undoRemove: async () => {
    if (lastRemoved.length === 0) return;
    const next = ordered([...(get().jobs ?? []), ...lastRemoved]);
    lastRemoved = [];
    set({ jobs: next });
    await persist(next);
  },

  /// The one write that overwrites, and the only one that reports whether the row was still there.
  applyStatus: async (jobId, status, message, httpStatus) => {
    let existed = false;
    // Read and write inside one updater: a delete landing between a find and a write would be
    // resurrected by the write, and this is the JavaScript equivalent of one update statement.
    set((state) => {
      const current = state.jobs ?? [];
      existed = current.some((row) => row.id === jobId);
      if (!existed) return state;
      return {
        ...state,
        jobs: current.map((row) =>
          row.id === jobId ? { ...row, status, message, httpStatus } : row,
        ),
      };
    });
    // Re-read, never a value captured before the await: a remove landing in that window is
    // already absent from what this writes, where a captured array would resurrect the row.
    if (existed) await persist(get().jobs ?? []);
    return existed;
  },

  /// The whole refresh sequence, owned by what owns the rows. Null means one is already in flight.
  refresh: async (jobId, session, nowMillis, source) => {
    if (inFlight.has(jobId)) return null;
    inFlight.add(jobId);
    try {
      const row = get().find(jobId);
      if (row === null) return { kind: 'failed', reason: 'The verification is no longer stored' };
      if (row.sessionId === null) return { kind: 'noServerJob' };
      if (session === null || session.expiresAtMillis <= nowMillis) return { kind: 'noSession' };
      // The partner, not the session: tokens expire and the same partner holds a newer one.
      if (session.partnerId !== row.partnerId) return { kind: 'partnerMismatch' };

      let outcome: UseSmileIDSampleStatusRefresh;
      try {
        // The row's environment, never the toggle: a row outlives the toggle that produced it.
        outcome = await source.check(jobId, session.token, row.sandbox);
      } catch (error) {
        // The type, never the message: this text goes on screen and a client error carries the URL.
        const name = error instanceof Error ? error.name : 'Error';
        return { kind: 'failed', reason: `Unexpected error: ${name}` };
      }
      if (outcome.kind !== 'updated') return outcome;

      const written = await get().applyStatus(
        jobId,
        outcome.status,
        outcome.message,
        outcome.httpCode,
      );
      return written ? outcome : { kind: 'failed', reason: 'The verification is no longer stored' };
    } finally {
      // Released even when the caller was cancelled, or the row is silently unrefreshable for the
      // rest of the process — which is what a `finally` buys that an early return does not.
      inFlight.delete(jobId);
    }
  },

  find: (jobId) => (get().jobs ?? []).find((row) => row.id === jobId) ?? null,

  /// Consume-once, so returning to the list cannot replay a confirmation already acted on.
  consumeRemoval: () => {
    const [first, ...rest] = get().removals;
    if (first === undefined) return null;
    set({ removals: rest });
    return first;
  },

  /// Reached only by the `seedJobs` launch argument. Idempotent: the rows are keyed by job id.
  seedFixtures: async (nowMillis) => {
    const current = get().jobs ?? [];
    const fresh = smileIDSampleJobFixtures(nowMillis).filter(
      (fixture) => !current.some((row) => row.id === fixture.id),
    );
    if (fresh.length === 0) return;
    const next = ordered([...current, ...fresh]);
    set({ jobs: next });
    await persist(next);
  },

  reset: () => {
    lastRemoved = [];
    inFlight.clear();
    set({ jobs: null, removals: [] });
  },
}));
