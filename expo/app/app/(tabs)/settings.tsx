import {
  SettingsScreen,
  smileIDSampleProfileInitials,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleFormsStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleSettingsStore,
  useSmileIDSampleTheme,
  avatarColorForProfile,
  type UseSmileIDSampleNavRow,
} from '@smileid/sample-ui';
import Constants from 'expo-constants';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';

import { smileIDSampleStartsExpired } from '../../src/flow/use-smile-id-sample-flow-launch-snapshot';
import { useLaunchArgs } from '../../src/use-smile-id-sample-launch';
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
  const { scenario } = useLaunchArgs();
  // Clock-free, so Settings does not re-render on the tick.
  const consentBound = useSmileIDSampleSessionStore((state) => state.live?.bindings.consent != null);
  const clearSession = useSmileIDSampleSessionStore((state) => state.clear);
  const clearForms = useSmileIDSampleFormsStore((state) => state.clear);

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
        consentBoundByToken: consentBound && !smileIDSampleStartsExpired(scenario),
      }}
      onSettingChange={(setting, enabled) => void setSetting(setting, enabled)}
      onProfilePress={() => router.push('/profiles')}
      onNavRowPress={onNavRowPress}
      // There is no auth to leave, so signing out is the local state a partner would expect gone.
      onSignOut={() => {
        clearSession().catch(() => undefined);
        clearForms();
        router.navigate('/products');
      }}
      bottomInset={bottomInset}
    />
  );
}
