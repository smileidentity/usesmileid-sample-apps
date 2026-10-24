import * as Linking from 'expo-linking';
import { useEffect } from 'react';
import { create } from 'zustand';

import {
  smileIDSampleLaunchArgDefaults,
  smileIDSampleLaunchArgsFromUrl,
  type UseSmileIDSampleLaunchArgs,
} from '@smileid/sample-ui';

import { useSmileIDSampleShellExtension } from './extension';

type State = {
  readonly args: UseSmileIDSampleLaunchArgs;
  /// The link the app launched at, or null for a launch from the icon.
  readonly url: string | null;
  /// False until the cold-start link is read; the root waits on it.
  readonly loaded: boolean;
  /// What the extension's `onLaunch` threw, which fails the launch.
  readonly failure: Error | null;
};

const useLaunchStore = create<State>(() => ({
  args: smileIDSampleLaunchArgDefaults,
  url: null,
  loaded: false,
  failure: null,
}));

let reading: Promise<void> | null = null;

/// Reads the cold-start link once per process, so a live link never re-seeds; the extension launches on it before the root renders.
export const smileIDSampleLoadLaunchArgs = (): Promise<void> => {
  reading ??= Linking.getInitialURL()
    .catch(() => null)
    .then(async (url) => {
      try {
        await useSmileIDSampleShellExtension?.onLaunch?.(url);
      } catch (error) {
        useLaunchStore.setState({ failure: error instanceof Error ? error : new Error(String(error)) });
        return;
      }
      useLaunchStore.setState({ args: smileIDSampleLaunchArgsFromUrl(url), url, loaded: true });
    })
    .catch(() => useLaunchStore.setState({ args: smileIDSampleLaunchArgDefaults, loaded: true }));
  return reading;
};

/// The launch arguments.
export const useLaunchArgs = (): UseSmileIDSampleLaunchArgs => {
  useEffect(() => {
    void smileIDSampleLoadLaunchArgs();
  }, []);
  return useLaunchStore((state) => state.args);
};

/// The cold-start link, which the shell opens once everything has loaded.
export const useLaunchUrl = (): string | null => useLaunchStore((state) => state.url);

/// Whether the cold-start link has been read.
export const useLaunchArgsLoaded = (): boolean => useLaunchStore((state) => state.loaded);

/// What the extension's `onLaunch` threw, or null while the launch stands.
export const useLaunchFailure = (): Error | null => useLaunchStore((state) => state.failure);

/// Forgets the read, for tests.
export const smileIDSampleResetLaunchArgs = (): void => {
  reading = null;
  useLaunchStore.setState({ args: smileIDSampleLaunchArgDefaults, url: null, loaded: false, failure: null });
};
