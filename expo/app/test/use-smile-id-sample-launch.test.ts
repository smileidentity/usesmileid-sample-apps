import { smileIDSampleLaunchArgDefaults } from '@smileid/sample-ui';
import { act, renderHook, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';

import {
  smileIDSampleLoadLaunchArgs,
  smileIDSampleResetLaunchArgs,
  useLaunchArgs,
  useLaunchArgsLoaded,
} from '../src/use-smile-id-sample-launch';
import type { UseSmileIDSampleShellExtension } from '../src/use-smile-id-sample-shell-extension';

jest.mock('expo-linking', () => ({ getInitialURL: jest.fn() }));
/// The extension a test installs; null is the registry build.
let mockExtension: UseSmileIDSampleShellExtension | null = null;
jest.mock('../src/extension', () => ({
  get useSmileIDSampleShellExtension() {
    return mockExtension;
  },
}));

const getInitialURL = Linking.getInitialURL as jest.MockedFunction<typeof Linking.getInitialURL>;

beforeEach(() => {
  getInitialURL.mockReset();
  smileIDSampleResetLaunchArgs();
  mockExtension = null;
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

describe('the cold-start link launches the extension', () => {
  it('hands onLaunch the link it read, once', async () => {
    const onLaunch = jest.fn();
    mockExtension = { onLaunch };
    const { result, rerender } = await launch(`${LAUNCH}?seedJobs=true`);
    await waitFor(() => expect(result.current.seedJobs).toBe(true));
    await rerender(undefined);

    expect(onLaunch).toHaveBeenCalledTimes(1);
    expect(onLaunch).toHaveBeenCalledWith(`${LAUNCH}?seedJobs=true`);
  });

  it('hands onLaunch no link when the link cannot be read', async () => {
    const onLaunch = jest.fn();
    mockExtension = { onLaunch };
    getInitialURL.mockRejectedValue(new Error('no activity is attached yet'));
    await renderHook(() => useLaunchArgs());
    await waitFor(() => expect(onLaunch).toHaveBeenCalledWith(null));
  });

  it('waits for an asynchronous onLaunch before the arguments load', async () => {
    let finish: (() => void) | undefined;
    mockExtension = {
      onLaunch: () =>
        new Promise<void>((resolve) => {
          finish = resolve;
        }),
    };
    getInitialURL.mockResolvedValue(`${LAUNCH}?seedJobs=true`);
    const { result } = await renderHook(() => ({ args: useLaunchArgs(), loaded: useLaunchArgsLoaded() }));
    await waitFor(() => expect(finish).toBeDefined());
    expect(result.current.loaded).toBe(false);

    await act(async () => finish?.());
    await waitFor(() => expect(result.current.loaded).toBe(true));
    expect(result.current.args.seedJobs).toBe(true);
  });

  it('fails the launch when onLaunch throws, so a mistyped run never starts', async () => {
    mockExtension = {
      onLaunch: () => {
        throw new Error('not a bundled scenario');
      },
    };
    getInitialURL.mockResolvedValue(`${LAUNCH}?seedJobs=true`);
    await expect(smileIDSampleLoadLaunchArgs()).rejects.toThrow('not a bundled scenario');
  });
});
