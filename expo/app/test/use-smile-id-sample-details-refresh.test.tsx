import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  UseSmileIDSampleStatus,
  UseSmileIDSampleThemeProvider,
  smileIDSampleBase64UrlEncode,
  smileIDSampleProducts,
  smileIDSampleTokenSession,
  useSmileIDSampleJobStore,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { act, render, waitFor } from '@testing-library/react-native';

import { UseSmileIDSampleVerificationDetailsStep } from '../src/steps/use-smile-id-sample-verification-details-step';
import { smileIDSampleStatusApi } from '../src/status/use-smile-id-sample-status-api';
import { smileIDSampleFakeScope } from './support/use-smile-id-sample-test-njia';

jest.mock('react-native-safe-area-context', () => ({
  useSafeAreaInsets: () => ({ top: 24, bottom: 48, left: 0, right: 0 }),
}));

jest.mock('../src/status/use-smile-id-sample-status-api', () => ({
  ...jest.requireActual('../src/status/use-smile-id-sample-status-api'),
  smileIDSampleStatusApi: { check: jest.fn() },
}));

const check = smileIDSampleStatusApi.check as jest.Mock;

/// A live fixture session, unsigned, as Simulate mints one.
const liveSession = () => {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const claims = `{"iat":${nowSeconds - 1},"exp":${nowSeconds + 900},"api_url":"https://testapi.smileidentity.com/v3"}`;
  return smileIDSampleTokenSession(['{"alg":"none"}', claims, 's'].map(smileIDSampleBase64UrlEncode).join('.'))!;
};

beforeEach(async () => {
  jest.useFakeTimers();
  check.mockReset();
  await AsyncStorage.clear();
  useSmileIDSampleJobStore.getState().reset();
  useSmileIDSampleSessionStore.getState().reset();
  await useSmileIDSampleJobStore.getState().load();
  await useSmileIDSampleJobStore.getState().add({
    id: 'job_waiting',
    userId: 'user_1',
    product: smileIDSampleProducts[0]!,
    status: UseSmileIDSampleStatus.Processing,
    createdAtMillis: Date.now(),
    message: 'Request accepted and queued for processing.',
    httpStatus: 202,
    sandbox: true,
    sessionId: 'session_1',
    partnerId: null,
  });
  await useSmileIDSampleSessionStore.getState().link(liveSession());
});

afterEach(() => {
  jest.useRealTimers();
});

describe('a verification still processing on its details page', () => {
  it('is asked about again until its verdict lands', async () => {
    check
      .mockResolvedValueOnce({ kind: 'stillProcessing' })
      .mockResolvedValueOnce({ kind: 'updated', status: UseSmileIDSampleStatus.Clear, message: 'Job completed', httpCode: 200 });
    const screen = await render(
      <UseSmileIDSampleThemeProvider dark={false}>
        <UseSmileIDSampleVerificationDetailsStep
          scope={smileIDSampleFakeScope('verificationDetails', { arg: 'job_waiting' }).scope}
        />
      </UseSmileIDSampleThemeProvider>,
    );
    await waitFor(() => expect(check).toHaveBeenCalledTimes(1));
    expect(screen.queryByText('Clear — Job completed')).toBeNull();

    await act(async () => {
      jest.advanceTimersByTime(5_000);
    });

    await waitFor(() => expect(screen.queryByText('Clear — Job completed')).not.toBeNull());
    expect(check).toHaveBeenCalledTimes(2);
    screen.unmount();
  });
});
