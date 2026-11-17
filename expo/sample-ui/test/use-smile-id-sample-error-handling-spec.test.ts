import {
  smileIDSampleErrorActions,
  UseSmileIDSampleErrorAction,
  UseSmileIDSampleErrorMessage,
  type UseSmileIDSampleErrorResolution,
  type UseSmileIDSampleTransportFailure,
} from '../src/model/use-smile-id-sample-error-resolution';
import {
  smileIDSampleErrorForReason,
  smileIDSampleErrorForStatus,
  smileIDSampleErrorForTransport,
  smileIDSampleErrorResultRows,
  smileIDSampleErrorSubmissionRows,
} from '../src/state/use-smile-id-sample-error-handling';
import { UseSmileIDSampleStrings } from '../src/use-smile-id-sample-strings';
import { spec } from './spec-file';

type SpecRow = {
  id: string;
  message: string;
  action: UseSmileIDSampleErrorAction;
  status?: number[];
  transport?: UseSmileIDSampleTransportFailure;
  reasons?: string[];
  serverMessageContains?: string[];
  backoffSeconds?: number[];
  maxUses?: number;
  waitsFor?: string;
};
type SpecCase = {
  status?: number;
  transport?: UseSmileIDSampleTransportFailure;
  reason?: string | null;
  serverMessage?: string;
  resolves: string;
};
const file = spec<{
  actions: Record<string, { button: string; maxUses?: number }>;
  submission: SpecRow[];
  result: SpecRow[];
  fallback: { submission: string; result: string };
  cases: SpecCase[];
}>('error-handling.json');
const strings = spec<Record<string, string>>('l10n/app/en.json');

/// A resolution as the spec states one, with the action's limit where the row has none.
const expected = (row: SpecRow) => ({
  id: row.id,
  message: row.message,
  action: row.action,
  backoffSeconds: row.backoffSeconds ?? [],
  maxUses: row.maxUses ?? file.actions[row.action]?.maxUses ?? null,
  waitsFor: row.waitsFor ?? null,
});

const stated = (resolution: UseSmileIDSampleErrorResolution) => ({
  id: resolution.id,
  message: resolution.message,
  action: resolution.action,
  backoffSeconds: [...resolution.backoffSeconds],
  maxUses: resolution.maxUses,
  waitsFor: resolution.waitsForConnection ? 'connection' : null,
});

const row = (id: string) => expected([...file.submission, ...file.result].find((candidate) => candidate.id === id)!);

const caseName = (c: SpecCase) => `${c.status ?? c.transport ?? c.reason} "${c.serverMessage ?? ''}"`;

/// spec/error-handling.json: the message and the one action every failure resolves to.
describe('the error handling table', () => {
  it("holds the spec's rows in order", () => {
    expect(smileIDSampleErrorSubmissionRows.map((r) => r.id)).toEqual(file.submission.map((r) => r.id));
    expect(smileIDSampleErrorResultRows.map((r) => r.id)).toEqual(file.result.map((r) => r.id));
  });

  it.each(file.submission.map((r) => [r.id, r] as const))('%s resolves to its message, action and limits', (_id, r) => {
    const text = r.serverMessageContains?.[0];
    for (const status of r.status ?? []) expect(stated(smileIDSampleErrorForStatus(status, text))).toEqual(expected(r));
    if (r.transport !== undefined) expect(stated(smileIDSampleErrorForTransport(r.transport))).toEqual(expected(r));
    expect((r.status ?? []).length + (r.transport === undefined ? 0 : 1)).toBeGreaterThan(0);
  });

  it.each(file.result.map((r) => [r.id, r] as const))('%s resolves to its message, action and limits', (_id, r) => {
    const text = r.serverMessageContains?.[0];
    expect(r.reasons?.length).toBeGreaterThan(0);
    for (const reason of r.reasons ?? []) expect(stated(smileIDSampleErrorForReason(reason, text))).toEqual(expected(r));
  });

  it.each(file.cases.map((c) => [caseName(c), c] as const))('%s resolves as the spec says', (_name, c) => {
    const resolved =
      c.status !== undefined
        ? smileIDSampleErrorForStatus(c.status, c.serverMessage)
        : c.transport !== undefined
          ? smileIDSampleErrorForTransport(c.transport)
          : smileIDSampleErrorForReason(c.reason, c.serverMessage);
    expect(resolved.id).toBe(c.resolves);
  });

  it('resolves a failure the table does not name as the fallback', () => {
    expect(stated(smileIDSampleErrorForStatus(599))).toEqual(row(file.fallback.submission));
    expect(stated(smileIDSampleErrorForReason('not_in_the_table'))).toEqual(row(file.fallback.result));
    expect(stated(smileIDSampleErrorForReason(null))).toEqual(row(file.fallback.result));
    expect(stated(smileIDSampleErrorForReason())).toEqual(row(file.fallback.result));
  });

  it('shows the one message for every fraud and compliance outcome', () => {
    const reasons = file.result.find((r) => r.id === 'notVerified')?.reasons ?? [];
    expect(reasons.length).toBeGreaterThan(1);
    for (const reason of reasons) {
      const resolved = smileIDSampleErrorForReason(reason, `Verification failed: ${reason}`);
      expect(resolved.message).toBe(UseSmileIDSampleErrorMessage.NotVerified);
      expect(resolved.action).toBe(UseSmileIDSampleErrorAction.Exit);
    }
    expect(UseSmileIDSampleStrings.forLanguage('en').errorNotVerified).toBe("We couldn't verify your identity.");
  });

  it("has the spec's actions, with its buttons and limits", () => {
    expect(Object.values(UseSmileIDSampleErrorAction)).toEqual(Object.keys(file.actions));
    for (const action of Object.values(UseSmileIDSampleErrorAction)) {
      expect(smileIDSampleErrorActions[action].buttonKey).toBe(file.actions[action]?.button);
      expect(smileIDSampleErrorActions[action].maxUses).toBe(file.actions[action]?.maxUses);
    }
  });

  it('has a string for every message and button', () => {
    const used = new Set([...file.submission, ...file.result].map((r) => r.message));
    expect(new Set<string>(Object.values(UseSmileIDSampleErrorMessage))).toEqual(used);
    for (const key of [...used, ...Object.values(smileIDSampleErrorActions).map((action) => action.buttonKey)]) {
      expect(strings[key]?.length ?? 0).toBeGreaterThan(0);
    }
  });
});
