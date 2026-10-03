import { AppearanceSheet, useSmileIDSampleSettingsStore } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

import { useSmileIDSampleDeviceScheme } from '../../../src/use-smile-id-sample-device-scheme';

/// Grouped outside the tabs, as Capture mode is, so Settings stays visible behind the sheet.
export default function Appearance() {
  const router = useRouter();
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.appearance);
  const setAppearance = useSmileIDSampleSettingsStore((state) => state.setAppearance);
  const deviceDark = useSmileIDSampleDeviceScheme((state) => state.deviceDark);
  // To Settings, not back: a cold link has the tabs' first page, Products, beneath the sheet.
  const close = () => router.dismissTo('/settings');

  return (
    <AppearanceSheet
      selected={selected}
      deviceDark={deviceDark}
      onSelect={(appearance) => {
        void setAppearance(appearance);
        close();
      }}
      onDismiss={close}
    />
  );
}
