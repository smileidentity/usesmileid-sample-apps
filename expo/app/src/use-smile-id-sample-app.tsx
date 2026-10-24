import {
  SMILE_ID_SAMPLE_NOTICE_WINDOW_MS,
  UseSmileIDSampleNoticeWindowProvider,
  UseSmileIDSampleStringsProvider,
  UseSmileIDSampleThemeProvider,
  smileDarkColors,
  smileFontAssets,
  smileLightColors,
  useSmileIDSampleJobStore,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSessionClock,
  useSmileIDSampleSessionStore,
  useSmileIDSampleSettingsStore,
  UseSmileIDSampleAppearance,
} from '@smileid/sample-ui';
import { useFonts } from 'expo-font';
import { NavigationBar } from 'expo-navigation-bar';
import { setStatusBarStyle, StatusBar } from 'expo-status-bar';
import { useEffect, useMemo, useRef } from 'react';
import { Appearance, Platform, useColorScheme, View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { useSmileIDSampleShellExtension } from './extension';
import {
  smileIDSampleCurrentLink,
  smileIDSampleOpenLink,
  smileIDSampleStartShell,
  UseSmileIDSampleShell,
} from './navigation/use-smile-id-sample-shell';
import { useSmileIDSampleAppLanguage } from './use-smile-id-sample-app-language';
import { useSmileIDSampleDeviceScheme } from './use-smile-id-sample-device-scheme';
import { useLaunchArgs, useLaunchArgsLoaded, useLaunchFailure, useLaunchUrl } from './use-smile-id-sample-launch';
import { smileIDSampleSecureProfilesStorage } from './use-smile-id-sample-secure-profiles-storage';
import { smileIDSampleSecureSessionStorage } from './use-smile-id-sample-secure-session-storage';
import { UseSmileIDSampleSelectModeProvider } from './use-smile-id-sample-select-mode';
import { linkLaunchSession } from './use-smile-id-sample-shell-extension';

/// Re-sends both bar styles, past the navigation-bar module's cache.
const reassertSystemBars = (dark: boolean) => {
  setStatusBarStyle(dark ? 'light' : 'dark');
  NavigationBar.setStyle(dark ? 'dark' : 'light');
  NavigationBar.setStyle(dark ? 'light' : 'dark');
};

/// The app's root: settings, session and launch arguments load, then njia's shell draws `spec/njia-graph.json`.
export const UseSmileIDSampleApp = () => {
  const scheme = useColorScheme();
  const appearance = useSmileIDSampleSettingsStore((state) => state.settings.appearance);
  const settingsLoaded = useSmileIDSampleSettingsStore((state) => state.loaded);
  const loadSettings = useSmileIDSampleSettingsStore((state) => state.load);
  const setDeviceDark = useSmileIDSampleDeviceScheme((state) => state.setDeviceDark);
  const following = !settingsLoaded || appearance === UseSmileIDSampleAppearance.System;
  // Before settings load the device decides, which is right for the default and avoids a flash.
  const dark = following ? scheme === 'dark' : appearance === UseSmileIDSampleAppearance.Dark;
  const colors = dark ? smileDarkColors : smileLightColors;
  const args = useLaunchArgs();
  const launchUrl = useLaunchUrl();
  const argsLoaded = useLaunchArgsLoaded();
  const launchFailure = useLaunchFailure();
  const loadProfiles = useSmileIDSampleProfileStore((state) => state.load);
  const profilesLoaded = useSmileIDSampleProfileStore((state) => state.loaded);
  const seedFixtures = useSmileIDSampleJobStore((state) => state.seedFixtures);
  // spec/launch-args.json states the argument in SECONDS; the library's window is milliseconds.
  const noticeWindowMs =
    args.noticeWindow === null ? SMILE_ID_SAMPLE_NOTICE_WINDOW_MS : args.noticeWindow * 1_000;

  // The five faces are bundled rather than fetched: a provider would make text depend on the network.
  const [fontsLoaded] = useFonts(smileFontAssets);

  useEffect(() => {
    void loadSettings();
  }, [loadSettings]);

  const sessionLoaded = useSmileIDSampleSessionStore((state) => state.loaded);
  const loadSession = useSmileIDSampleSessionStore((state) => state.load);
  useEffect(() => {
    void loadSession(smileIDSampleSecureSessionStorage);
  }, [loadSession]);
  useSmileIDSampleSessionClock();

  // Only while nothing is pinned: a pin makes useColorScheme report the app's choice, not the device's.
  useEffect(() => {
    if (following) setDeviceDark(scheme === 'dark');
  }, [following, scheme, setDeviceDark]);

  // The SDK's useColorScheme and the native bars read this, not the theme provider; 'unspecified' unpins.
  useEffect(() => {
    if (settingsLoaded) {
      Appearance.setColorScheme(appearance === UseSmileIDSampleAppearance.System ? 'unspecified' : appearance);
    }
  }, [settingsLoaded, appearance]);

  // Android re-applies the window's bars after a night-mode change, so ours go again, with the event's theme under System.
  useEffect(() => {
    if (Platform.OS !== 'android') return undefined;
    const subscription = Appearance.addChangeListener(({ colorScheme }) =>
      requestAnimationFrame(() =>
        reassertSystemBars(
          appearance === UseSmileIDSampleAppearance.System
            ? colorScheme === 'dark'
            : appearance === UseSmileIDSampleAppearance.Dark,
        ),
      ),
    );
    return () => subscription.remove();
  }, [appearance]);

  useEffect(() => {
    // Once, off the link's own arguments: the defaults before it resolves are no launch at all.
    if (!argsLoaded) return;
    void loadProfiles(args, smileIDSampleSecureProfilesStorage);
    // Before the verifications route's first load, or its own read wins and the list opens empty.
    // Caught, not voided: a failed write must degrade to an empty list, never an unhandled rejection.
    if (args.seedJobs) seedFixtures(Date.now()).catch(() => undefined);
  }, [args, argsLoaded, loadProfiles, seedFixtures]);

  const ready = fontsLoaded && sessionLoaded && argsLoaded && profilesLoaded;
  const routing = useMemo(
    () => ({ currentLink: smileIDSampleCurrentLink, reopen: (link: string) => smileIDSampleOpenLink(link, args) }),
    [args],
  );
  const { language, deviceLanguages } = useSmileIDSampleAppLanguage(args.appLocale, ready, routing);

  // Once, when everything has loaded; the session links first because an autostarted run needs it.
  const launched = useRef(false);
  useEffect(() => {
    if (!ready || launched.current) return;
    launched.current = true;
    void linkLaunchSession(useSmileIDSampleShellExtension, (session) =>
      useSmileIDSampleSessionStore.getState().link(session),
    )
      .catch(() => undefined)
      .then(() => smileIDSampleStartShell(launchUrl, args));
  }, [ready, launchUrl, args]);

  if (launchFailure) throw launchFailure;
  if (!ready) {
    return <View style={{ backgroundColor: colors.background, flex: 1 }} />;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
    <SafeAreaProvider>
      <UseSmileIDSampleStringsProvider language={language} deviceLanguages={deviceLanguages}>
        <UseSmileIDSampleThemeProvider dark={dark}>
          <UseSmileIDSampleNoticeWindowProvider value={noticeWindowMs}>
            <StatusBar style={dark ? 'light' : 'dark'} />
            {/* Names the button colour, as StatusBar does, despite the type's doc saying the bar's. */}
            <NavigationBar style={dark ? 'light' : 'dark'} />
            <UseSmileIDSampleSelectModeProvider>
              <UseSmileIDSampleShell args={args} />
            </UseSmileIDSampleSelectModeProvider>
          </UseSmileIDSampleNoticeWindowProvider>
        </UseSmileIDSampleThemeProvider>
      </UseSmileIDSampleStringsProvider>
    </SafeAreaProvider>
    </GestureHandlerRootView>
  );
};
