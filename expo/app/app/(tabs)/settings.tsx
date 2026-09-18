import {
  SettingsScreen,
  smileIDSampleProfileInitials,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleSettingsStore,
  useSmileIDSampleTheme,
  avatarColorForProfile,
  type UseSmileIDSampleNavRow,
} from '@smileid/sample-ui';
import Constants from 'expo-constants';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';

import { openNavRow } from '../../src/use-smile-id-sample-links';
import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';

/// The Settings footer names the product and the host's own version, which only a shell can read.
const versionLabel = () => `Smile ID · ${Constants.expoConfig?.version ?? '0.0.0'}`;

export default function Settings() {
  const theme = useSmileIDSampleTheme();
  const router = useRouter();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
  const settings = useSmileIDSampleSettingsStore((state) => state.settings);
  const setSetting = useSmileIDSampleSettingsStore((state) => state.setSetting);
  const load = useSmileIDSampleSettingsStore((state) => state.load);
  const bottomInset = useSmileIDSampleListInset();

  useEffect(() => {
    void load();
  }, [load]);

  const onNavRowPress = (row: UseSmileIDSampleNavRow) => {
    if (row.id === 'licenses') {
      router.push('/settings/licenses');
      return;
    }
    // Per scheme: one shared toolbar colour left a white bar on a white page.
    void openNavRow(row, theme.dark ? theme.colors.surface : theme.colors.primary);
  };

  return (
    <SettingsScreen
      state={{
        settings,
        organisation: profile.organisation,
        initials: smileIDSampleProfileInitials(profile),
        versionLabel: versionLabel(),
        avatarColor: avatarColorForProfile(index),
      }}
      onSettingChange={(setting, enabled) => void setSetting(setting, enabled)}
      onProfilePress={() => router.push('/profiles')}
      onNavRowPress={onNavRowPress}
      onSignOut={() => undefined}
      bottomInset={bottomInset}
    />
  );
}
