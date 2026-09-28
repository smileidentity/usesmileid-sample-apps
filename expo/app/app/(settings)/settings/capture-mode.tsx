import { CaptureModeSheet, useSmileIDSampleSettingsStore } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

/// Grouped outside the tabs, as the profile switch is, so Settings stays visible behind the sheet.
export default function CaptureMode() {
  const router = useRouter();
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.captureMode);
  const setCaptureMode = useSmileIDSampleSettingsStore((state) => state.setCaptureMode);
  // To Settings, not back: a cold link has the tabs' first page, Products, beneath the sheet.
  const close = () => router.dismissTo('/settings');

  return (
    <CaptureModeSheet
      selected={selected}
      onSelect={(mode) => {
        void setCaptureMode(mode);
        close();
      }}
      onDismiss={close}
    />
  );
}
