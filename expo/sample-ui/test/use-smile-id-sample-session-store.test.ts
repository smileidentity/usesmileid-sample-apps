import { act, renderHook } from '@testing-library/react-native';

import {
  smileIDSampleLiveSession,
  smileIDSampleSessionExpired,
  useSmileIDSampleSessionClock,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleSessionStorage,
} from '../src/state/use-smile-id-sample-session-store';
import { smileIDSampleTokenSession } from '../src/state/use-smile-id-sample-token-decoder';

const base64Url = (text: string) => Buffer.from(text, 'utf8').toString('base64url');
const tokenFor = (iatSeconds: number, expSeconds: number) =>
  ['{"alg":"none"}', `{"iat":${iatSeconds},"exp":${expSeconds},"api_url":"https://testapi.smileidentity.com/v3"}`, 's']
    .map(base64Url)
    .join('.');

/// A storage whose bytes the test can read, standing in for the platform secure store.
const recordingStorage = (initial: string | null = null) => {
  let value = initial;
  const storage: UseSmileIDSampleSessionStorage = {
    read: async () => value,
    write: async (next) => {
      value = next;
    },
  };
  return { storage, stored: () => value };
};

const now = Date.now();
const liveToken = tokenFor(Math.floor(now / 1000), Math.floor(now / 1000) + 900);

beforeEach(() => useSmileIDSampleSessionStore.getState().reset());

describe('the session store', () => {
  it('starts with no session and no marker, so a plain launch is the no-token journey', async () => {
    const { storage } = recordingStorage();
    await useSmileIDSampleSessionStore.getState().load(storage);
    const state = useSmileIDSampleSessionStore.getState();
    expect(state.live).toBeNull();
    expect(state.ended).toBeNull();
    expect(state.loaded).toBe(true);
  });

  it('persists the token as the whole live record and reads it back decoded', async () => {
    const { storage, stored } = recordingStorage();
    await useSmileIDSampleSessionStore.getState().load(storage);
    await useSmileIDSampleSessionStore.getState().link(smileIDSampleTokenSession(liveToken)!);
    expect(JSON.parse(stored()!)).toEqual({ token: liveToken });

    useSmileIDSampleSessionStore.getState().reset();
    await useSmileIDSampleSessionStore.getState().load(recordingStorage(stored()).storage);
    expect(useSmileIDSampleSessionStore.getState().live?.token).toBe(liveToken);
  });

  it('retires a session by deleting the credential and keeping only its handle and deadline', async () => {
    const { storage, stored } = recordingStorage();
    await useSmileIDSampleSessionStore.getState().load(storage);
    const session = smileIDSampleTokenSession(liveToken)!;
    await useSmileIDSampleSessionStore.getState().link(session);
    await useSmileIDSampleSessionStore.getState().retire(session);
    expect(stored()).not.toContain(liveToken);
    expect(JSON.parse(stored()!)).toEqual({ endedId: session.id, endedAt: session.expiresAtMillis });
    expect(smileIDSampleSessionExpired(useSmileIDSampleSessionStore.getState(), now)).toBe(true);
  });

  it('clears both halves on sign out, so the next run is not sent to the scanner', async () => {
    const { storage, stored } = recordingStorage();
    await useSmileIDSampleSessionStore.getState().load(storage);
    const session = smileIDSampleTokenSession(liveToken)!;
    await useSmileIDSampleSessionStore.getState().link(session);
    await useSmileIDSampleSessionStore.getState().retire(session);
    await useSmileIDSampleSessionStore.getState().clear();
    expect(stored()).toBeNull();
    expect(smileIDSampleSessionExpired(useSmileIDSampleSessionStore.getState(), now)).toBe(false);
  });

  it('reads an unreadable or undecodable record as no session rather than a degraded one', async () => {
    await useSmileIDSampleSessionStore.getState().load(recordingStorage('{not json').storage);
    expect(useSmileIDSampleSessionStore.getState().live).toBeNull();
    await useSmileIDSampleSessionStore.getState().load(recordingStorage('{"token":"sample-not-a-jwt"}').storage);
    expect(useSmileIDSampleSessionStore.getState().live).toBeNull();
  });

  it('offers a run only the session live at that instant', () => {
    const session = smileIDSampleTokenSession(liveToken)!;
    expect(smileIDSampleLiveSession({ live: session }, session.expiresAtMillis - 1)).toBe(session);
    expect(smileIDSampleLiveSession({ live: session }, session.expiresAtMillis)).toBeNull();
  });

  it('retires a session whose deadline passed while the app was closed, on the first tick', async () => {
    const expired = tokenFor(Math.floor(now / 1000) - 1000, Math.floor(now / 1000) - 100);
    const { storage, stored } = recordingStorage(JSON.stringify({ token: expired }));
    await useSmileIDSampleSessionStore.getState().load(storage);
    renderHook(() => useSmileIDSampleSessionClock());
    await act(async () => {
      await Promise.resolve();
    });
    expect(useSmileIDSampleSessionStore.getState().live).toBeNull();
    expect(useSmileIDSampleSessionStore.getState().ended).not.toBeNull();
    expect(stored()).not.toContain(expired);
  });

  it('holds the interrupted run until the scanner drops it', () => {
    useSmileIDSampleSessionStore.getState().sendRun({ productId: 'enhancedKyc', route: 'shell' });
    expect(useSmileIDSampleSessionStore.getState().pendingRun).toEqual({ productId: 'enhancedKyc', route: 'shell' });
    useSmileIDSampleSessionStore.getState().clearRun();
    expect(useSmileIDSampleSessionStore.getState().pendingRun).toBeNull();
  });

  it('never lets a late retirement of a stale session end a fresher one linked before it', async () => {
    // Writes that take a while to land, as the platform secure store's do.
    let stored: string | null = null;
    const slow: UseSmileIDSampleSessionStorage = {
      read: async () => stored,
      write: (next) =>
        new Promise((resolve) =>
          setTimeout(() => {
            stored = next;
            resolve();
          }, 20),
        ),
    };
    const stale = smileIDSampleTokenSession(tokenFor(Math.floor(now / 1000) - 1000, Math.floor(now / 1000) - 100))!;
    stored = JSON.stringify({ token: stale.token });
    await useSmileIDSampleSessionStore.getState().load(slow);

    const fresh = smileIDSampleTokenSession(liveToken)!;
    const linking = useSmileIDSampleSessionStore.getState().link(fresh);
    // The tick that saw the stale session fires after the link, as a timer queued before it would.
    const retiring = useSmileIDSampleSessionStore.getState().retire(stale);
    await Promise.all([linking, retiring]);

    expect(useSmileIDSampleSessionStore.getState().live?.id).toBe(fresh.id);
    expect(useSmileIDSampleSessionStore.getState().ended).toBeNull();
    expect(JSON.parse(stored!)).toEqual({ token: fresh.token });
  });

  it('retires a stale stored session before a first link on a cold start, and the link then wins', async () => {
    let stored: string | null = null;
    const slow: UseSmileIDSampleSessionStorage = {
      read: async () => stored,
      write: (next) => new Promise((resolve) => setTimeout(() => ((stored = next), resolve()), 20)),
    };
    const stale = tokenFor(Math.floor(now / 1000) - 1000, Math.floor(now / 1000) - 100);
    stored = JSON.stringify({ token: stale });
    await useSmileIDSampleSessionStore.getState().load(slow);
    renderHook(() => useSmileIDSampleSessionClock());
    const fresh = smileIDSampleTokenSession(liveToken)!;
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(fresh);
    });
    expect(useSmileIDSampleSessionStore.getState().live?.id).toBe(fresh.id);
    expect(JSON.parse(stored!)).toEqual({ token: fresh.token });
  });
});

