import { smileIDSampleLaunchArgDefaults } from '@smileid/sample-ui';
import { renderHook, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';

import { smileIDSampleResetLaunchArgs, useLaunchArgs } from '../src/use-smile-id-sample-launch';

jest.mock('expo-linking', () => ({ getInitialURL: jest.fn() }));

const getInitialURL = Linking.getInitialURL as jest.MockedFunction<typeof Linking.getInitialURL>;

beforeEach(() => {
  getInitialURL.mockReset();
  smileIDSampleResetLaunchArgs();
});

/// The scheme spec/app-identity.json reserves for this app, which is what a cold start arrives on.
const LAUNCH = 'usesmileid-sample-expo://';

const launch = async (url: string | null) => {
  getInitialURL.mockResolvedValue(url);
  const rendered = await renderHook(() => useLaunchArgs());
  // The first render is the defaults; the link resolves a tick later, so the read has to be awaited.
  await waitFor(() => expect(getInitialURL).toHaveBeenCalled());
  return rendered;
};

describe('the cold-start link decides the launch arguments', () => {
  it('takes an argument the link carries', async () => {
    const { result } = await launch(`${LAUNCH}?seedJobs=true`);
    await waitFor(() => expect(result.current.seedJobs).toBe(true));
  });

  it('takes the plain defaults when there is no link', async () => {
    const { result } = await launch(null);
    await waitFor(() => expect(result.current).toEqual(smileIDSampleLaunchArgDefaults));
  });

  it('falls back to the defaults when the link cannot be read', async () => {
    getInitialURL.mockRejectedValue(new Error('no activity is attached yet'));
    const { result } = await renderHook(() => useLaunchArgs());
    await waitFor(() => expect(getInitialURL).toHaveBeenCalled());
    expect(result.current).toEqual(smileIDSampleLaunchArgDefaults);
  });

  it('reads the link once, so one delivered to a live app cannot re-seed the arguments', async () => {
    const { result, rerender } = await launch(`${LAUNCH}?seedJobs=true&seedProfiles=true`);
    await waitFor(() => expect(result.current.seedJobs).toBe(true));

    getInitialURL.mockResolvedValue(`${LAUNCH}?seedJobs=false&seedProfiles=false`);
    await rerender(undefined);

    expect(getInitialURL).toHaveBeenCalledTimes(1);
    expect(result.current.seedProfiles).toBe(true);
  });
});
