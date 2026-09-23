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
  /// False until the cold-start link is read, which the root waits on so no route snapshots the defaults.
  readonly loaded: boolean;
};

const useLaunchStore = create<State>(() => ({ args: smileIDSampleLaunchArgDefaults, loaded: false }));

let reading: Promise<void> | null = null;

/// Reads the cold-start link once per process: a link delivered to a live app must never re-seed the arguments.
export const smileIDSampleLoadLaunchArgs = (): Promise<void> => {
  reading ??= Linking.getInitialURL()
    .then((url) => smileIDSampleLaunchArgsFromUrl(url))
    .catch(() => smileIDSampleLaunchArgDefaults)
    .then((args) => useLaunchStore.setState({ args, loaded: true }));
  return reading;
};

/// The launch arguments, the same value on every screen from the first frame the root lets through.
export const useLaunchArgs = (): UseSmileIDSampleLaunchArgs => {
  useEffect(() => {
    void smileIDSampleLoadLaunchArgs();
  }, []);
  return useLaunchStore((state) => state.args);
};

/// Whether the cold-start link has been read.
export const useLaunchArgsLoaded = (): boolean => useLaunchStore((state) => state.loaded);

/// Forgets the read, so each test starts as a cold start does.
export const smileIDSampleResetLaunchArgs = (): void => {
  reading = null;
  useLaunchStore.setState({ args: smileIDSampleLaunchArgDefaults, loaded: false });
};
