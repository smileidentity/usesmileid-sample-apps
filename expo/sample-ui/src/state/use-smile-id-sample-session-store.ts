import { useEffect } from 'react';
import { create } from 'zustand';

import type { UseSmileIDSampleFlowRoute } from '../model/use-smile-id-sample-scenario';
import { smileIDSampleTokenSession } from './use-smile-id-sample-token-decoder';
import {
  smileIDSampleSessionHasExpired,
  type UseSmileIDSampleEndedSession,
  type UseSmileIDSampleTokenSession,
} from './use-smile-id-sample-token-session';

/// Where the session record's bytes live: the platform's secure store in an app, memory in a test.
export type UseSmileIDSampleSessionStorage = {
  read: () => Promise<string | null>;
  /// Null deletes the record.
  write: (value: string | null) => Promise<void>;
};

/// A run the expiry gate sent away, carrying the presentation it was launched in.
export type UseSmileIDSampleRunIntent = {
  readonly productId: string;
  readonly route: UseSmileIDSampleFlowRoute;
};

/// The whole persisted record, one item so the token and the ended marker can never come from different writes.
type StoredRecord = {
  readonly token?: string;
  readonly endedId?: string;
  readonly endedAt?: number;
};

type State = {
  /// At most one of `live` and `ended` is ever set: retiring swaps the token for its marker in one write.
  readonly live: UseSmileIDSampleTokenSession | null;
  readonly ended: UseSmileIDSampleEndedSession | null;
  readonly loaded: boolean;
  /// Ticks once a second while a session is live; only what shows the countdown reads it.
  readonly nowMillis: number;
  /// The expiry gate's hand-off to the scanner — app state, never a route argument.
  readonly pendingRun: UseSmileIDSampleRunIntent | null;
};

type Actions = {
  /// Adopts the shell's storage and reads the record it holds.
  load: (storage: UseSmileIDSampleSessionStorage) => Promise<void>;
  /// Takes the session rather than the raw token, so only a decoded one can ever be linked.
  link: (session: UseSmileIDSampleTokenSession) => Promise<void>;
  /// Deletes the credential at its deadline, keeping only that the session ended.
  retire: (session: UseSmileIDSampleTokenSession) => Promise<void>;
  /// Sign out: no ended marker, which would send the next run to the scanner.
  clear: () => Promise<void>;
  tick: (nowMillis: number) => void;
  sendRun: (intent: UseSmileIDSampleRunIntent) => void;
  clearRun: () => void;
  reset: () => void;
};

const memoryStorage = (): UseSmileIDSampleSessionStorage => {
  let value: string | null = null;
  return {
    read: async () => value,
    write: async (next) => {
      value = next;
    },
  };
};

let storage: UseSmileIDSampleSessionStorage = memoryStorage();
/// Writes land in the order they were made, so a quick link-then-retire cannot persist backwards.
let writes: Promise<void> = Promise.resolve();

const persist = (record: StoredRecord | null): Promise<void> => {
  const target = storage;
  writes = writes
    .catch(() => undefined)
    .then(() => target.write(record === null ? null : JSON.stringify(record)));
  return writes;
};

const recordFrom = (text: string | null): Pick<State, 'live' | 'ended'> => {
  if (text === null) return { live: null, ended: null };
  try {
    const record = JSON.parse(text) as StoredRecord;
    const live = typeof record.token === 'string' ? smileIDSampleTokenSession(record.token) : null;
    const ended =
      live === null && typeof record.endedId === 'string'
        ? { id: record.endedId, endedAtMillis: typeof record.endedAt === 'number' ? record.endedAt : 0 }
        : null;
    return { live, ended };
  } catch {
    // An unreadable record is no session rather than a degraded one.
    return { live: null, ended: null };
  }
};

/// The token session. The token is the whole live record: every other field decodes from it.
export const useSmileIDSampleSessionStore = create<State & Actions>((set) => ({
  live: null,
  ended: null,
  loaded: false,
  nowMillis: Date.now(),
  pendingRun: null,

  load: async (next) => {
    storage = next;
    let text: string | null = null;
    try {
      text = await next.read();
    } catch {
      text = null;
    }
    set({ ...recordFrom(text), loaded: true, nowMillis: Date.now() });
  },

  link: async (session) => {
    set({ live: session, ended: null, nowMillis: Date.now() });
    await persist({ token: session.token });
  },

  retire: async (session) => {
    set({ live: null, ended: { id: session.id, endedAtMillis: session.expiresAtMillis } });
    await persist({ endedId: session.id, endedAt: session.expiresAtMillis });
  },

  clear: async () => {
    set({ live: null, ended: null });
    await persist(null);
  },

  tick: (nowMillis) => set({ nowMillis }),
  sendRun: (intent) => set({ pendingRun: intent }),
  clearRun: () => set({ pendingRun: null }),

  reset: () => {
    storage = memoryStorage();
    writes = Promise.resolve();
    set({ live: null, ended: null, loaded: false, nowMillis: Date.now(), pendingRun: null });
  },
}));

/// True from the deadline on; reads the marker too, since the token is deleted at expiry.
export const smileIDSampleSessionExpired = (
  state: Pick<State, 'live' | 'ended'>,
  nowMillis: number,
): boolean => state.ended !== null || (state.live !== null && smileIDSampleSessionHasExpired(state.live, nowMillis));

/// The session a run may submit under at `nowMillis`, or null.
export const smileIDSampleLiveSession = (
  state: Pick<State, 'live'>,
  nowMillis: number,
): UseSmileIDSampleTokenSession | null =>
  state.live !== null && !smileIDSampleSessionHasExpired(state.live, nowMillis) ? state.live : null;

/// Ticks once a second while a session is live, and retires it at its deadline — a cold start after expiry included.
export const useSmileIDSampleSessionClock = (): void => {
  const live = useSmileIDSampleSessionStore((state) => state.live);
  useEffect(() => {
    if (live === null) return undefined;
    const { tick, retire } = useSmileIDSampleSessionStore.getState();
    const step = () => {
      const now = Date.now();
      tick(now);
      if (!smileIDSampleSessionHasExpired(live, now)) return false;
      void retire(live).catch(() => undefined);
      return true;
    };
    if (step()) return undefined;
    const timer = setInterval(() => {
      if (step()) clearInterval(timer);
    }, TICK_MILLIS);
    return () => clearInterval(timer);
  }, [live]);
};

const TICK_MILLIS = 1000;
