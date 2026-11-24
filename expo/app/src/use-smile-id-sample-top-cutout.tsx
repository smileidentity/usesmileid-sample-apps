import { requireOptionalNativeModule } from 'expo';
import { useCallback, useSyncExternalStore, type ReactNode } from 'react';
import { Platform } from 'react-native';
import { UseSmileIDSampleTopCutoutContext } from '@smileid/sample-ui';

/// The app's own Android module: a top-cutout reading it keeps on the UI thread, and the event it sends when that changes.
export type UseSmileIDSampleCutoutModule = {
  hasTopCutout(): boolean;
  addListener(
    event: 'onTopCutoutChange',
    listener: (event: { present: boolean }) => void,
  ): { remove(): void };
};

const nativeCutout =
  Platform.OS === 'android' ? requireOptionalNativeModule<UseSmileIDSampleCutoutModule>('UseSmileIDSampleCutout') : null;

/// Tells the shared screens whether the phone has a camera cutout along its top edge, following each change the native module sends.
export const UseSmileIDSampleTopCutoutProvider = ({
  children,
  cutout = nativeCutout,
}: {
  children: ReactNode;
  cutout?: UseSmileIDSampleCutoutModule | null;
}) => {
  const subscribe = useCallback(
    (onChange: () => void) => {
      const subscription = cutout?.addListener('onTopCutoutChange', onChange);
      return () => subscription?.remove();
    },
    [cutout],
  );
  const present = useSyncExternalStore(subscribe, () => cutout?.hasTopCutout() ?? false);
  return <UseSmileIDSampleTopCutoutContext.Provider value={present}>{children}</UseSmileIDSampleTopCutoutContext.Provider>;
};
