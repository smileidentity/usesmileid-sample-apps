import { useEffect } from 'react';
import { create } from 'zustand';

import type { UseSmileIDSampleFlowRoute } from '../model/use-smile-id-sample-scenario';
import { smileIDSampleTokenSession } from './use-smile-id-sample-token-decoder';
import {
  smileIDSampleSessionHasExpired,
  type UseSmileIDSampleEndedSession,
  type UseSmileIDSampleTokenSession,
} from './use-smile-id-sample-token-session';

/// Where the session record's bytes live.
export type UseSmileIDSampleSessionStorage = {
  read: () => Promise<string | null>;
  /// Null deletes the record.
  write: (value: string | null) => Promise<void>;
};

/// A run the expiry gate sent to the scanner.
export type UseSmileIDSampleRunIntent = {
  readonly productId: string;
  readonly route: UseSmileIDSampleFlowRoute;
};

/// The persisted record, one item so token and marker never come from different writes.
type StoredRecord = {
  readonly token_session_token?: string;
  readonly ended_session_id?: string;
  readonly ended_session_at?: number;
};

type State = {
  /// At most one of `live` and `ended` is set.
  readonly live: UseSmileIDSampleTokenSession | null;
  readonly ended: UseSmileIDSampleEndedSession | null;
  readonly loaded: boolean;
  /// Ticks once a second while a session is live.
  readonly nowMillis: number;
  /// The expiry gate's hand-off to the scanner, never a route argument.
  readonly pendingRun: UseSmileIDSampleRunIntent | null;
};

type Actions = {
  /// Adopts the shell's storage and reads its record.
  load: (storage: UseSmileIDSampleSessionStorage) => Promise<void>;
  /// Links a decoded session.
  link: (session: UseSmileIDSampleTokenSession) => Promise<void>;
  /// Deletes the credential at its deadline, keeping a marker; a no-op once another is live.
  retire: (session: UseSmileIDSampleTokenSession) => Promise<void>;
  /// Sign out: no ended marker.
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
/// Writes land in call order.
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
    const token = record.token_session_token;
    const live = typeof token === 'string' ? smileIDSampleTokenSession(token) : null;
    const endedId = record.ended_session_id;
    const endedAt = record.ended_session_at;
    const ended =
      live === null && typeof endedId === 'string'
        ? { id: endedId, endedAtMillis: typeof endedAt === 'number' ? endedAt : 0 }
        : null;
    return { live, ended };
  } catch {
    return { live: null, ended: null };
  }
};

/// The token session; the token is the whole live record.
export const useSmileIDSampleSessionStore = create<State & Actions>((set, get) => ({
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
    await persist({ token_session_token: session.token });
  },

  retire: async (session) => {
    // Checked and written in one step, so a tick queued before a relink cannot end it.
    if (get().live?.token !== session.token) return;
    set({ live: null, ended: { id: session.id, endedAtMillis: session.expiresAtMillis } });
    await persist({ ended_session_id: session.id, ended_session_at: session.expiresAtMillis });
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

/// True from the deadline on, the marker included.
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

/// Ticks while a session is live and retires it at its deadline, cold starts included.
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
