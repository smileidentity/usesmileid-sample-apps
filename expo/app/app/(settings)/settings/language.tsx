import { LanguageSheet, useSmileIDSampleDeviceLanguages, useSmileIDSampleSettingsStore } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

/// Grouped outside the tabs, as Capture mode is, so Settings stays visible behind the sheet.
export default function Language() {
  const router = useRouter();
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.language);
  const setLanguage = useSmileIDSampleSettingsStore((state) => state.setLanguage);
  const deviceLanguages = useSmileIDSampleDeviceLanguages();
  // To Settings, not back: a cold link has the tabs' first page, Products, beneath the sheet.
  const close = () => router.dismissTo('/settings');

  return (
    <LanguageSheet
      selected={selected}
      deviceLanguages={deviceLanguages}
      onSelect={(language) => {
        void setLanguage(language);
        close();
      }}
      onDismiss={close}
    />
  );
}
