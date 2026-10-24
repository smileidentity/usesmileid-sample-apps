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
  smileIDSampleProfileTitle,
  useSmileIDSampleProfileStore,
  useSmileIDSampleStrings,
} from '@smileid/sample-ui';
import Constants from 'expo-constants';
import { useEffect } from 'react';

import { useSmileIDSampleShellExtension } from '../extension';
import { smileIDSampleStartsExpired } from '../flow/use-smile-id-sample-token-binding-rules';
import {
  smileIDSampleLeaveToProducts,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { useSmileIDSampleDeviceScheme } from '../use-smile-id-sample-device-scheme';
import { useLaunchArgs } from '../use-smile-id-sample-launch';
import { openNavRow } from '../use-smile-id-sample-links';
import { useSmileIDSampleListInset } from '../use-smile-id-sample-list-inset';
import { smileIDSampleDebugRows } from '../use-smile-id-sample-shell-extension';

/// The Settings footer names the product and the host's own version, which only a shell can read.
const versionLabel = () => `Smile ID · ${Constants.expoConfig?.version ?? '0.0.0'}`;

/// The settings tab, whose rows open their sheets and pages over it.
export const UseSmileIDSampleSettingsStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const theme = useSmileIDSampleTheme();
  const engine = useSmileIDSampleEngine();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
  const settings = useSmileIDSampleSettingsStore((state) => state.settings);
  const setSetting = useSmileIDSampleSettingsStore((state) => state.setSetting);
  const load = useSmileIDSampleSettingsStore((state) => state.load);
  const bottomInset = useSmileIDSampleListInset();
  const deviceDark = useSmileIDSampleDeviceScheme((state) => state.deviceDark);
  const { scenario } = useLaunchArgs();
  // Clock-free: Settings must not re-render on the tick.
  const consentBound = useSmileIDSampleSessionStore((state) => state.live?.bindings.consent != null);
  const clearSession = useSmileIDSampleSessionStore((state) => state.clear);
  const clearForms = useSmileIDSampleFormsStore((state) => state.clear);
  const clearProfiles = useSmileIDSampleProfileStore((state) => state.clear);

  useEffect(() => {
    void load();
  }, [load]);

  const onNavRowPress = (row: UseSmileIDSampleNavRow) => {
    if (row.id === 'licenses') {
      scope.navigator.go('licenses');
      return;
    }
    // Per scheme: one shared toolbar colour left a white bar on a white page.
    void openNavRow(row, theme.dark ? theme.colors.surface : theme.colors.primary);
  };

  return (
    <SettingsScreen
      state={{
        settings,
        organisation: profile === null ? strings.profilesNoProfile : smileIDSampleProfileTitle(profile, strings),
        initials: profile === null ? '' : smileIDSampleProfileInitials(profile),
        hasProfile: profile !== null,
        versionLabel: versionLabel(),
        avatarColor: avatarColorForProfile(index),
        consentBoundByToken: consentBound && !smileIDSampleStartsExpired(scenario),
        deviceDark,
      }}
      onSettingChange={(setting, enabled) => void setSetting(setting, enabled)}
      onProfilePress={() => scope.navigator.go('profiles')}
      onNavRowPress={onNavRowPress}
      onCaptureModePress={() => scope.navigator.go('captureMode')}
      onAppearancePress={() => scope.navigator.go('appearance')}
      onLanguagePress={() => scope.navigator.go('language')}
      onSignOut={() => {
        clearSession().catch(() => undefined);
        clearForms();
        clearProfiles();
        smileIDSampleLeaveToProducts(engine);
      }}
      debugRows={smileIDSampleDebugRows(useSmileIDSampleShellExtension)}
      bottomInset={bottomInset}
    />
  );
};
