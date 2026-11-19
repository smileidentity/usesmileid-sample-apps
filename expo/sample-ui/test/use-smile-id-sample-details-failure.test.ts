import { type UseSmileIDSampleJob } from '../src/model/use-smile-id-sample-job';
import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import {
  smileIDSampleBannerTone,
  smileIDSampleDetailsFailure,
  smileIDSampleLandedFailure,
} from '../src/state/use-smile-id-sample-details-failure';
import { smileIDSampleErrorForReason, smileIDSampleErrorForStatus } from '../src/state/use-smile-id-sample-error-handling';

/// Which failure verification details states, and how its banner reads.
describe('the details failure', () => {
  const serverError = smileIDSampleErrorForStatus(503);
  const job = (status: UseSmileIDSampleStatus): UseSmileIDSampleJob => ({
    id: 'job_1',
    userId: 'user_1',
    product: smileIDSampleProducts.find((it) => it.id === 'biometricKyc')!,
    status,
    createdAtMillis: 0,
    message: 'Rejected',
    httpStatus: 200,
    sandbox: true,
    sessionId: null,
    partnerId: null,
  });

  it('a run that failed before any job states its own row', () => {
    expect(smileIDSampleDetailsFailure(undefined, serverError)).toBe(serverError);
  });

  it('a failed run no submission explains states that it ended before submission', () => {
    const landed = smileIDSampleLandedFailure('failed', undefined);
    expect(landed?.id).toBe('endedBeforeSubmission');
    expect(landed && smileIDSampleBannerTone(landed)).toBe('warning');
  });

  it('a run that did not fail lands with no failure', () => {
    for (const status of ['captured', 'succeeded', 'cancelled'] as const) {
      expect(smileIDSampleLandedFailure(status, serverError)).toBeUndefined();
    }
    expect(smileIDSampleLandedFailure('failed', serverError)).toBe(serverError);
  });

  it('a missing job with no failed run states nothing', () => {
    expect(smileIDSampleDetailsFailure(undefined, undefined)).toBeUndefined();
  });

  it('a job that ended in error or block states the fallback until the status carries a reason', () => {
    for (const status of [UseSmileIDSampleStatus.Error, UseSmileIDSampleStatus.Blocked]) {
      expect(smileIDSampleDetailsFailure(job(status), serverError)?.id).toBe('notVerified');
    }
  });

  it('a job with any other status states nothing even after a failed run', () => {
    for (const status of [UseSmileIDSampleStatus.Clear, UseSmileIDSampleStatus.Attention, UseSmileIDSampleStatus.Processing]) {
      expect(smileIDSampleDetailsFailure(job(status), serverError)).toBeUndefined();
    }
  });

  it('a failure trying again later can get past is a warning and a final one an error', () => {
    expect(smileIDSampleBannerTone(serverError)).toBe('warning');
    expect(smileIDSampleBannerTone(smileIDSampleErrorForReason(null))).toBe('error');
  });
});
