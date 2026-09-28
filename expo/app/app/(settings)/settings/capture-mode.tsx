import { CaptureModeSheet, useSmileIDSampleSettingsStore } from '@smileid/sample-ui';

import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';

/// Grouped outside the tabs, as the profile switch is, so Settings stays visible behind the sheet.
export default function CaptureMode() {
  const back = useSmileIDSampleBack('/settings');
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.captureMode);
  const setCaptureMode = useSmileIDSampleSettingsStore((state) => state.setCaptureMode);

  return (
    <CaptureModeSheet
      selected={selected}
      onSelect={(mode) => {
        void setCaptureMode(mode);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
