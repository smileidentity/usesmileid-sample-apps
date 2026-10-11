import type { UseSmileIDSampleJob } from '../src/model/use-smile-id-sample-job';
import { smileIDSampleProductFrom } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { useSmileIDSampleFormsStore } from '../src/state/use-smile-id-sample-forms-store';
import { smileIDSampleJobMiddleUserId } from '../src/model/use-smile-id-sample-job';
import { smileIDSamplePreviousAuthUsers } from '../src/state/use-smile-id-sample-auth-user-ids';

const previousIds = (...args: Parameters<typeof smileIDSamplePreviousAuthUsers>) =>
  smileIDSamplePreviousAuthUsers(...args).map((found) => found.userId);

const PARTNER = 'partner-a';

const job = (
  userId: string,
  productId: string,
  status: UseSmileIDSampleStatus,
  at: number,
  partnerId: string | null = PARTNER,
  sandbox = true,
): UseSmileIDSampleJob => ({
  id: `job_${at}`,
  userId,
  product: smileIDSampleProductFrom(productId)!,
  status,
  createdAtMillis: at,
  message: '',
  httpStatus: 200,
  sandbox,
  sessionId: null,
  partnerId,
});

/// Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed.
describe('the previous user IDs', () => {
  it('offer each user with the newest run that enrolled it', () => {
    expect(
      smileIDSamplePreviousAuthUsers([
        job('user_a', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 1),
        job('user_b', 'biometricKyc', UseSmileIDSampleStatus.Clear, 2),
        job('user_a', 'documentVerification', UseSmileIDSampleStatus.Clear, 3),
      ], PARTNER, true).map((found) => found.id),
    ).toEqual(['job_3', 'job_2']);
  });

  it("keep a long ID's head and tail", () => {
    expect(smileIDSampleJobMiddleUserId(job('user_01m4gahg4ceceatsw25mc5dd1h', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 1))).toBe('user_01m4…mc5dd1h');
    expect(smileIDSampleJobMiddleUserId(job('user_short', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 1))).toBe('user_short');
  });

  it('are newest first and once each, from every product that enrols a user', () => {
    expect(
      previousIds([
        job('user_a', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 1),
        job('user_b', 'biometricKyc', UseSmileIDSampleStatus.Attention, 3),
        job('user_c', 'documentVerification', UseSmileIDSampleStatus.Processing, 2),
        job('user_a', 'enhancedDocumentVerification', UseSmileIDSampleStatus.Clear, 4),
      ], PARTNER, true),
    ).toEqual(['user_a', 'user_b', 'user_c']);
  });

  it('leave out refused, failed, authentication and Enhanced KYC runs', () => {
    expect(
      previousIds([
        job('user_blocked', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Blocked, 1),
        job('user_error', 'biometricKyc', UseSmileIDSampleStatus.Error, 2),
        job('user_auth', 'smartSelfieAuth', UseSmileIDSampleStatus.Clear, 3),
        job('user_ekyc', 'enhancedKyc', UseSmileIDSampleStatus.Clear, 4),
        job(' ', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 5),
      ], PARTNER, true),
    ).toEqual([]);
  });
});

it("leaves out another partner's users, or this partner's in the other environment", () => {
  const jobs = [
    job('user_mine', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 1),
    job('user_theirs', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 2, 'partner-b'),
    job('user_production', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 3, PARTNER, false),
    job('user_fixture', 'smartSelfieEnrollment', UseSmileIDSampleStatus.Clear, 4, null),
  ];
  expect(previousIds(jobs, PARTNER, true)).toEqual(['user_mine']);
  expect(previousIds(jobs, null, true)).toEqual([]);
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
