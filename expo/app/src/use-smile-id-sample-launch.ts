import * as Linking from 'expo-linking';
import { useEffect, useState } from 'react';

import {
  smileIDSampleLaunchArgDefaults,
  smileIDSampleLaunchArgsFromUrl,
  type UseSmileIDSampleLaunchArgs,
} from '@smileid/sample-ui';

/// Reads the launch arguments once, from the cold-start link only: a link delivered to a live app
/// must never re-seed them, or it would discard whatever the drawer chose after launch.
export const useLaunchArgs = (): UseSmileIDSampleLaunchArgs => {
  const [args, setArgs] = useState(smileIDSampleLaunchArgDefaults);

  useEffect(() => {
    let cancelled = false;
    Linking.getInitialURL()
      .then((url) => {
        if (!cancelled) setArgs(smileIDSampleLaunchArgsFromUrl(url));
      })
      .catch(() => {
        if (!cancelled) setArgs(smileIDSampleLaunchArgDefaults);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return args;
};
