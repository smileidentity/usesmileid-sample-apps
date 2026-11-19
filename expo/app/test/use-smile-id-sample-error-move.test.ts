import { UseSmileIDSampleErrorAction, smileIDSampleProducts } from '@smileid/sample-ui';

import { smileIDSampleErrorMove } from '../src/flow/use-smile-id-sample-error-move';

/// Where each failure action takes the user, per the `does` lines of spec/error-handling.json.
describe('smileIDSampleErrorMove', () => {
  const product = smileIDSampleProducts.find((it) => it.id === 'biometricKyc')!;

  it('a retry a later retry and a recapture run the verification again', () => {
    for (const action of [
      UseSmileIDSampleErrorAction.Retry,
      UseSmileIDSampleErrorAction.RetryLater,
      UseSmileIDSampleErrorAction.Recapture,
    ]) {
      expect(smileIDSampleErrorMove(action, product)).toEqual({ kind: 'runAgain', product });
    }
  });

  it('fixing the input returns to the id form', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.FixInput, product)).toEqual({
      kind: 'editIdDetails',
      product,
    });
  });

  it('starting again takes a new token first', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.NewSession, product)).toEqual({
      kind: 'newToken',
      product,
    });
  });

  it('close leaves the run', () => {
    expect(smileIDSampleErrorMove(UseSmileIDSampleErrorAction.Exit, product)).toEqual({ kind: 'leave' });
  });

  it('a run whose product was not kept can only leave', () => {
    for (const action of Object.values(UseSmileIDSampleErrorAction)) {
      expect(smileIDSampleErrorMove(action, null)).toEqual({ kind: 'leave' });
    }
  });
});
