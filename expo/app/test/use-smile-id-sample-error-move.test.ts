import { UseSmileIDSampleErrorAction, smileIDSampleProducts } from '@smileid/sample-ui';

import { smileIDSampleErrorMove, type UseSmileIDSampleErrorGate } from '../src/flow/use-smile-id-sample-error-move';

/// Where each failure action takes the user, per the `does` lines of spec/error-handling.json, under the gate a product tap passes.
describe('smileIDSampleErrorMove', () => {
  const product = smileIDSampleProducts.find((it) => it.id === 'biometricKyc')!;
  const reruns = [UseSmileIDSampleErrorAction.Retry, UseSmileIDSampleErrorAction.RetryLater, UseSmileIDSampleErrorAction.Recapture];
  const gate = (overrides: Partial<UseSmileIDSampleErrorGate> = {}): UseSmileIDSampleErrorGate => ({
    sessionLive: true,
    livePartnerId: 'partner_1',
    runPartnerId: 'partner_1',
    idDetails: 'form',
    ...overrides,
  });

  it("a retry a later retry and a recapture run the verification again on the run's own partner", () => {
    for (const action of reruns) {
      expect(smileIDSampleErrorMove(action, product, gate())).toEqual({ kind: 'runAgain', product });
    }
  });

  it('a rerun on another or an unknown partner starts from the first step', () => {
    for (const action of reruns) {
      expect(smileIDSampleErrorMove(action, product, gate({ livePartnerId: 'partner_2' }))).toEqual({ kind: 'runFromStart', product });
      expect(smileIDSampleErrorMove(action, product, gate({ livePartnerId: 'partner_2', runPartnerId: null }))).toEqual({
        kind: 'runFromStart',
        product,
      });
    }
  });

  it('a rerun with no live session scans first and resumes in the flow', () => {
    for (const action of reruns) {
      expect(smileIDSampleErrorMove(action, product, gate({ sessionLive: false }))).toEqual({ kind: 'newToken', product, resumeAt: 'flow' });
    }
  });

  it('fixing the input returns to the id form or scans first with no live session', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.FixInput, product, gate())).toEqual({ kind: 'editIdDetails', product });
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.FixInput, product, gate({ sessionLive: false }))).toEqual({
      kind: 'newToken',
      product,
      resumeAt: 'firstStep',
    });
  });

  it('fixing the input on another partner starts from the first step with fresh forms', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.FixInput, product, gate({ livePartnerId: 'partner_2' }))).toEqual({
      kind: 'runFromStart',
      product,
    });
  });

  it('fixing input the token carries takes a new token and a product with no id form starts again', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.FixInput, product, gate({ idDetails: 'token' }))).toEqual({
      kind: 'newToken',
      product,
      resumeAt: 'firstStep',
    });
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.FixInput, product, gate({ idDetails: 'none' }))).toEqual({
      kind: 'runFromStart',
      product,
    });
  });

  it('starting again takes a new token first', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.NewSession, product, gate())).toEqual({
      kind: 'newToken',
      product,
      resumeAt: 'flow',
    });
  });

  it('close leaves the run', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.Exit, product, gate())).toEqual({ kind: 'leave' });
  });

  it('a run whose product was not kept can only leave', () => {
    for (const action of Object.values(UseSmileIDSampleErrorAction)) {
      expect(smileIDSampleErrorMove(action, null, gate())).toEqual({ kind: 'leave' });
    }
  });
});
