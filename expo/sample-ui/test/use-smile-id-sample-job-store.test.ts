import AsyncStorage from '@react-native-async-storage/async-storage';

import { smileIDSampleJobFixtures } from '../src/data/use-smile-id-sample-job-fixtures';
import {
  useSmileIDSampleJobStore,
  type UseSmileIDSampleRefreshSession,
} from '../src/data/use-smile-id-sample-job-store';
import type {
  UseSmileIDSampleJobStatusSource,
  UseSmileIDSampleStatusRefresh,
} from '../src/data/use-smile-id-sample-job-status-source';
import type { UseSmileIDSampleJob } from '../src/model/use-smile-id-sample-job';
import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';

const NOW = 1_800_000_000_000;

const store = () => useSmileIDSampleJobStore.getState();

const job = (overrides: Partial<UseSmileIDSampleJob> = {}): UseSmileIDSampleJob => ({
  id: 'job_1',
  userId: 'user_1',
  product: smileIDSampleProducts[0]!,
  status: UseSmileIDSampleStatus.Processing,
  createdAtMillis: NOW,
  message: 'Submitted, awaiting result',
  httpStatus: 202,
  sandbox: true,
  sessionId: 'sess_1',
  partnerId: 'partner_1',
  ...overrides,
});

const session = (
  overrides: Partial<UseSmileIDSampleRefreshSession> = {},
): UseSmileIDSampleRefreshSession => ({
  token: 'tok',
  partnerId: 'partner_1',
  expiresAtMillis: NOW + 60_000,
  ...overrides,
});

const sourceReturning = (outcome: UseSmileIDSampleStatusRefresh): UseSmileIDSampleJobStatusSource => ({
  check: async () => outcome,
});

beforeEach(async () => {
  await AsyncStorage.clear();
  store().reset();
  await store().load();
});

describe('a store that has not read yet', () => {
  it('is not the same as a store with no verifications', async () => {
    store().reset();
    expect(useSmileIDSampleJobStore.getState().jobs).toBeNull();
    await store().load();
    expect(useSmileIDSampleJobStore.getState().jobs).toEqual([]);
  });
});

describe('add', () => {
  it('stores a row and persists it', async () => {
    await store().add(job());
    expect(store().jobs).toHaveLength(1);
    expect(await AsyncStorage.getItem('sample.jobs.v3')).toContain('job_1');
  });

  it('is a no-op on an id already stored, so a repeated delivery is harmless', async () => {
    await store().add(job());
    await store().add(job({ message: 'a second delivery' }));
    expect(store().jobs).toHaveLength(1);
    expect(store().jobs?.[0]?.message).toBe('Submitted, awaiting result');
  });

  it('orders newest first, whatever order rows arrive in', async () => {
    await store().add(job({ id: 'older', createdAtMillis: NOW - 1000 }));
    await store().add(job({ id: 'newer', createdAtMillis: NOW }));
    expect(store().jobs?.map((row) => row.id)).toEqual(['newer', 'older']);
  });
});

describe('remove and undo', () => {
  it('takes the rows and reports the batch size once', async () => {
    await store().add(job({ id: 'a' }));
    await store().add(job({ id: 'b' }));
    await store().remove(['a', 'b']);
    expect(store().jobs).toEqual([]);
    expect(store().consumeRemoval()).toBe(2);
    expect(store().consumeRemoval()).toBeNull();
  });

  it('puts the batch back, in its own order, without recording one', async () => {
    await store().add(job({ id: 'older', createdAtMillis: NOW - 1000 }));
    await store().add(job({ id: 'newer', createdAtMillis: NOW }));
    await store().remove(['older', 'newer']);
    await store().undoRemove();
    expect(store().jobs?.map((row) => row.id)).toEqual(['newer', 'older']);
  });

  it('does not spend an undoable batch on a removal that took nothing', async () => {
    await store().add(job({ id: 'a' }));
    await store().remove(['a']);
    // An id with no row would otherwise overwrite the batch and silently lose the undo.
    await store().remove(['does-not-exist']);
    await store().undoRemove();
    expect(store().jobs?.map((row) => row.id)).toEqual(['a']);
  });

  it('reports nothing for a removal that took nothing', async () => {
    await store().remove(['does-not-exist']);
    expect(store().consumeRemoval()).toBeNull();
  });

  it('is a no-op with nothing pending', async () => {
    await store().add(job({ id: 'a' }));
    await store().undoRemove();
    expect(store().jobs?.map((row) => row.id)).toEqual(['a']);
  });

  it('leaves only the most recent batch undoable', async () => {
    await store().add(job({ id: 'a' }));
    await store().add(job({ id: 'b' }));
    await store().remove(['a']);
    await store().remove(['b']);
    await store().undoRemove();
    expect(store().jobs?.map((row) => row.id)).toEqual(['b']);
  });
});

describe('applyStatus', () => {
  it('rewrites the row and says it existed', async () => {
    await store().add(job());
    const written = await store().applyStatus('job_1', UseSmileIDSampleStatus.Clear, 'Approved', 200);
    expect(written).toBe(true);
    expect(store().jobs?.[0]).toMatchObject({
      status: UseSmileIDSampleStatus.Clear,
      message: 'Approved',
      httpStatus: 200,
    });
  });

  it('says a deleted row did not exist rather than resurrecting it', async () => {
    await store().add(job());
    await store().remove(['job_1']);
    const written = await store().applyStatus('job_1', UseSmileIDSampleStatus.Clear, 'Approved', 200);
    expect(written).toBe(false);
    expect(store().jobs).toEqual([]);
  });

  it('stores the code and not its display text', async () => {
    await store().add(job());
    await store().applyStatus('job_1', UseSmileIDSampleStatus.Clear, 'Approved', 200);
    expect(store().jobs?.[0]?.httpStatus).toBe(200);
    expect(await AsyncStorage.getItem('sample.jobs.v3')).not.toContain('200 OK');
  });
});

describe('refresh', () => {
  const updated: UseSmileIDSampleStatusRefresh = {
    kind: 'updated',
    status: UseSmileIDSampleStatus.Clear,
    message: 'Approved',
    httpCode: 200,
  };

  it('reads the row, asks the source and writes back', async () => {
    await store().add(job());
    const outcome = await store().refresh('job_1', session(), NOW, sourceReturning(updated));
    expect(outcome).toEqual(updated);
    expect(store().jobs?.[0]?.status).toBe(UseSmileIDSampleStatus.Clear);
  });

  it('takes the environment from the row, never from a toggle', async () => {
    await store().add(job({ sandbox: false }));
    let asked: boolean | null = null;
    await store().refresh('job_1', session(), NOW, {
      check: async (_id, _token, sandbox) => {
        asked = sandbox;
        return updated;
      },
    });
    expect(asked).toBe(false);
  });

  it('matches on the partner, so a newer session for the same partner still refreshes', async () => {
    await store().add(job({ partnerId: 'partner_1', sessionId: 'sess_OLD' }));
    const outcome = await store().refresh(
      'job_1',
      session({ partnerId: 'partner_1' }),
      NOW,
      sourceReturning(updated),
    );
    expect(outcome).toEqual(updated);
  });

  it('reports a partner mismatch rather than sending another account the credential', async () => {
    await store().add(job({ partnerId: 'partner_1' }));
    const outcome = await store().refresh(
      'job_1',
      session({ partnerId: 'partner_2' }),
      NOW,
      sourceReturning(updated),
    );
    expect(outcome).toEqual({ kind: 'partnerMismatch' });
  });

  it('says a fixture row was never submitted, before any partner check', async () => {
    await store().add(job({ sessionId: null, partnerId: null }));
    const outcome = await store().refresh('job_1', session(), NOW, sourceReturning(updated));
    expect(outcome).toEqual({ kind: 'noServerJob' });
  });

  it('says there is no session when the live one has expired', async () => {
    await store().add(job());
    const outcome = await store().refresh(
      'job_1',
      session({ expiresAtMillis: NOW - 1 }),
      NOW,
      sourceReturning(updated),
    );
    expect(outcome).toEqual({ kind: 'noSession' });
  });

  it('reports a missing row rather than throwing', async () => {
    const outcome = await store().refresh('nope', session(), NOW, sourceReturning(updated));
    expect(outcome).toEqual({ kind: 'failed', reason: 'The verification is no longer stored' });
  });

  it('reports a transport failure by type, never by message', async () => {
    await store().add(job());
    const outcome = await store().refresh('job_1', session(), NOW, {
      check: async () => {
        // A client error carries the request URL, and this text goes on screen.
        const error = new Error('GET https://api.example/v3/status?token=SECRET failed');
        error.name = 'TypeError';
        throw error;
      },
    });
    expect(outcome).toEqual({ kind: 'failed', reason: 'Unexpected error: TypeError' });
    expect(JSON.stringify(outcome)).not.toContain('SECRET');
  });

  it('passes a non-updated outcome straight through without writing', async () => {
    await store().add(job());
    const outcome = await store().refresh(
      'job_1',
      session(),
      NOW,
      sourceReturning({ kind: 'stillProcessing' }),
    );
    expect(outcome).toEqual({ kind: 'stillProcessing' });
    expect(store().jobs?.[0]?.status).toBe(UseSmileIDSampleStatus.Processing);
  });

  it('skips a second request for a row already in flight', async () => {
    await store().add(job());
    let started = 0;
    let release = () => {};
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    const slow: UseSmileIDSampleJobStatusSource = {
      check: async () => {
        started += 1;
        await gate;
        return updated;
      },
    };
    const first = store().refresh('job_1', session(), NOW, slow);
    const second = await store().refresh('job_1', session(), NOW, slow);
    expect(second).toBeNull();
    release();
    await first;
    expect(started).toBe(1);
  });

  it('releases the in-flight guard even when the source throws', async () => {
    await store().add(job());
    const throwing: UseSmileIDSampleJobStatusSource = {
      check: async () => {
        throw new Error('boom');
      },
    };
    await store().refresh('job_1', session(), NOW, throwing);
    // Unrefreshable for the rest of the process is the failure a released guard prevents.
    const second = await store().refresh('job_1', session(), NOW, sourceReturning(updated));
    expect(second).toEqual(updated);
  });
});

describe('the fixtures', () => {
  it('are reached only by seeding, never by a plain load', async () => {
    expect(store().jobs).toEqual([]);
  });

  it('seed the eleven the design counts describe', async () => {
    await store().seedFixtures(NOW);
    expect(store().jobs).toHaveLength(11);
  });

  it('match the chip counts the design draws', async () => {
    await store().seedFixtures(NOW);
    const counts = (status: UseSmileIDSampleStatus) =>
      (store().jobs ?? []).filter((row) => row.status === status).length;
    expect({
      all: store().jobs?.length,
      clear: counts(UseSmileIDSampleStatus.Clear),
      attention: counts(UseSmileIDSampleStatus.Attention),
      blocked: counts(UseSmileIDSampleStatus.Blocked),
    }).toEqual({ all: 11, clear: 6, attention: 2, blocked: 2 });
  });

  it('are idempotent, so one flow can seed on every launch', async () => {
    await store().seedFixtures(NOW);
    await store().seedFixtures(NOW + 5000);
    expect(store().jobs).toHaveLength(11);
  });

  it('carry no session, so a refresh says never submitted rather than mismatched', () => {
    expect(smileIDSampleJobFixtures(NOW).every((row) => row.sessionId === null)).toBe(true);
  });
});

describe('a row read back from storage', () => {
  it('survives a round trip with its product and status resolved', async () => {
    await store().add(job());
    store().reset();
    await store().load();
    expect(store().jobs?.[0]).toMatchObject({
      id: 'job_1',
      status: UseSmileIDSampleStatus.Processing,
      partnerId: 'partner_1',
    });
    expect(store().jobs?.[0]?.product.id).toBe(smileIDSampleProducts[0]!.id);
  });

  it('drops a row whose product no longer exists rather than crashing the restore', async () => {
    await AsyncStorage.setItem(
      'sample.jobs.v3',
      JSON.stringify([{ ...job(), product: 'aProductThatWasRenamed' }]),
    );
    store().reset();
    await store().load();
    expect(store().jobs).toEqual([]);
  });

  it('falls back on a status that no longer exists rather than throwing', async () => {
    await AsyncStorage.setItem(
      'sample.jobs.v3',
      JSON.stringify([{ ...job(), product: smileIDSampleProducts[0]!.id, status: 'Renamed' }]),
    );
    store().reset();
    await store().load();
    expect(store().jobs?.[0]?.status).toBe(UseSmileIDSampleStatus.Processing);
  });

  it('reads as empty when the stored value no longer parses', async () => {
    await AsyncStorage.setItem('sample.jobs.v3', 'not json');
    store().reset();
    await store().load();
    expect(store().jobs).toEqual([]);
  });
});

describe('the removal confirmation', () => {
  it('is consumed once, so returning to the list cannot replay it', async () => {
    await store().add(job({ id: 'job_a' }));
    await store().remove(['job_a']);

    expect(store().consumeRemoval()).toBe(1);
    expect(store().consumeRemoval()).toBeNull();
  });

  it('reports what each removal took, in the order they happened', async () => {
    await store().add(job({ id: 'job_a' }));
    await store().add(job({ id: 'job_b' }));
    await store().add(job({ id: 'job_c' }));
    await store().remove(['job_a']);
    await store().remove(['job_b', 'job_c']);

    expect(store().consumeRemoval()).toBe(1);
    expect(store().consumeRemoval()).toBe(2);
    expect(store().consumeRemoval()).toBeNull();
  });

  it('undoes the batch the newest confirmation names, which is the only one still shown', async () => {
    await store().add(job({ id: 'job_a' }));
    await store().add(job({ id: 'job_b' }));
    await store().remove(['job_a']);
    await store().remove(['job_b']);

    await store().undoRemove();

    // A second removal replaces the visible notice, so the batch undo restores is the one it names.
    expect(store().jobs?.map((row) => row.id)).toContain('job_b');
    expect(store().jobs?.map((row) => row.id)).not.toContain('job_a');
  });
});
