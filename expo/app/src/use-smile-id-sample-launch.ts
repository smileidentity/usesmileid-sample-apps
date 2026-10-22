import * as Linking from 'expo-linking';
import { useEffect } from 'react';
import { create } from 'zustand';

import {
  smileIDSampleLaunchArgDefaults,
  smileIDSampleLaunchArgsFromUrl,
  type UseSmileIDSampleLaunchArgs,
} from '@smileid/sample-ui';

type State = {
  readonly args: UseSmileIDSampleLaunchArgs;
  /// The cold-start link the arguments were read from, or null when there was none.
  readonly url: string | null;
  /// False until the cold-start link is read; the root waits on it.
  readonly loaded: boolean;
};

const useLaunchStore = create<State>(() => ({ args: smileIDSampleLaunchArgDefaults, url: null, loaded: false }));

let reading: Promise<void> | null = null;

/// Reads the cold-start link once per process, so a live link never re-seeds.
export const smileIDSampleLoadLaunchArgs = (): Promise<void> => {
  reading ??= Linking.getInitialURL()
    .then((url) => ({ args: smileIDSampleLaunchArgsFromUrl(url), url }))
    .catch(() => ({ args: smileIDSampleLaunchArgDefaults, url: null }))
    .then((read) => useLaunchStore.setState({ ...read, loaded: true }));
  return reading;
};

/// The launch arguments.
export const useLaunchArgs = (): UseSmileIDSampleLaunchArgs => {
  useEffect(() => {
    void smileIDSampleLoadLaunchArgs();
  }, []);
  return useLaunchStore((state) => state.args);
};

/// Whether the cold-start link has been read.
export const useLaunchArgsLoaded = (): boolean => useLaunchStore((state) => state.loaded);

/// The cold-start link, once read; null before then or when there was none.
export const smileIDSampleLaunchUrl = (): string | null => useLaunchStore.getState().url;

/// Forgets the read, for tests.
export const smileIDSampleResetLaunchArgs = (): void => {
  reading = null;
  useLaunchStore.setState({ args: smileIDSampleLaunchArgDefaults, url: null, loaded: false });
};
