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
  /// False until the cold-start link is read; the root waits on it.
  readonly loaded: boolean;
};

const useLaunchStore = create<State>(() => ({ args: smileIDSampleLaunchArgDefaults, loaded: false }));

let reading: Promise<void> | null = null;

/// Reads the cold-start link once per process, so a live link never re-seeds.
export const smileIDSampleLoadLaunchArgs = (): Promise<void> => {
  reading ??= Linking.getInitialURL()
    .then((url) => smileIDSampleLaunchArgsFromUrl(url))
    .catch(() => smileIDSampleLaunchArgDefaults)
    .then((args) => useLaunchStore.setState({ args, loaded: true }));
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

/// Forgets the read, for tests.
export const smileIDSampleResetLaunchArgs = (): void => {
  reading = null;
  useLaunchStore.setState({ args: smileIDSampleLaunchArgDefaults, loaded: false });
};
