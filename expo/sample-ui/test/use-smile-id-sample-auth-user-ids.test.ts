import type { UseSmileIDSampleJob } from '../src/model/use-smile-id-sample-job';
import { smileIDSampleProductFrom } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { useSmileIDSampleFormsStore } from '../src/state/use-smile-id-sample-forms-store';
import { smileIDSamplePreviousAuthUserIds } from '../src/state/use-smile-id-sample-auth-user-ids';

const job = (userId: string, productId: string, status: UseSmileIDSampleStatus, at: number): UseSmileIDSampleJob => ({
  id: `job_${at}`,
  userId,
  product: smileIDSampleProductFrom(productId)!,
  status,
  createdAtMillis: at,
  message: '',
  httpStatus: 200,
  sandbox: true,
  sessionId: null,
  partnerId: null,
});

/// Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed.
describe('the previous user IDs', () => {
  it('are newest first and once each, from every product that enrols a user', () => {
    expect(
      smileIDSamplePreviousAuthUserIds([
        job('user_a', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 1),
        job('user_b', 'biometricKyc', UseSmileIDSampleStatus.Attention, 3),
        job('user_c', 'documentVerification', UseSmileIDSampleStatus.Processing, 2),
        job('user_a', 'enhancedDocumentVerification', UseSmileIDSampleStatus.Clear, 4),
      ]),
    ).toEqual(['user_a', 'user_b', 'user_c']);
  });

  it('leave out refused, failed, authentication and Enhanced KYC runs', () => {
    expect(
      smileIDSamplePreviousAuthUserIds([
        job('user_blocked', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Blocked, 1),
        job('user_error', 'biometricKyc', UseSmileIDSampleStatus.Error, 2),
        job('user_auth', 'smartSelfieAuth', UseSmileIDSampleStatus.Clear, 3),
        job('user_ekyc', 'enhancedKyc', UseSmileIDSampleStatus.Clear, 4),
        job(' ', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 5),
      ]),
    ).toEqual([]);
  });
});

describe("authentication's user ID in the forms", () => {
  it('is kept until a new run or a sign-out drops it', () => {
    const forms = useSmileIDSampleFormsStore.getState();
    forms.setAuthUserId('user_01m4gahg4ceceatsw25mc5dd1h');
    expect(useSmileIDSampleFormsStore.getState().authUserId).toBe('user_01m4gahg4ceceatsw25mc5dd1h');
    forms.startRun(null);
    expect(useSmileIDSampleFormsStore.getState().authUserId).toBe('');
    forms.setAuthUserId('user_x');
    forms.clear();
    expect(useSmileIDSampleFormsStore.getState().authUserId).toBe('');
  });
});
