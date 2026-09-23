import {
  SMILE_ID_SAMPLE_NOTICE_WINDOW_MS,
  UseSmileIDSampleNoticeWindowProvider,
  UseSmileIDSampleThemeProvider,
  smileDarkColors,
  smileFontAssets,
  smileIDSampleProfilesForLaunch,
  smileLightColors,
  useSmileIDSampleJobStore,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSettingsStore,
} from '@smileid/sample-ui';
import { useFonts } from 'expo-font';
import { NavigationBar } from 'expo-navigation-bar';
import { Stack } from 'expo-router';
import { setStatusBarStyle, StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { Appearance, Platform, useColorScheme, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { useLaunchArgs } from '../src/use-smile-id-sample-launch';

/// Every pushed route and sheet layers over the tabs, so a cold deep link lands with its owner beneath (routes.json R12).
export const unstable_settings = { initialRouteName: '(tabs)' };

/// Re-sends both bar styles, past the navigation-bar module's cache.
const reassertSystemBars = (dark: boolean) => {
  setStatusBarStyle(dark ? 'light' : 'dark');
  NavigationBar.setStyle(dark ? 'dark' : 'light');
  NavigationBar.setStyle(dark ? 'light' : 'dark');
};

/// The navigation host. Every route is a file under app/, matching the expo column of spec/routes.json.
export default function RootLayout() {
  const scheme = useColorScheme();
  const darkMode = useSmileIDSampleSettingsStore((state) => state.settings.darkMode);
  const settingsLoaded = useSmileIDSampleSettingsStore((state) => state.loaded);
  const loadSettings = useSmileIDSampleSettingsStore((state) => state.load);
  // Until the switch loads, the device's guess avoids a flash.
  const dark = settingsLoaded ? darkMode : scheme === 'dark';
  const colors = dark ? smileDarkColors : smileLightColors;
  const args = useLaunchArgs();
  const resetProfiles = useSmileIDSampleProfileStore((state) => state.reset);
  const seedFixtures = useSmileIDSampleJobStore((state) => state.seedFixtures);
  // spec/launch-args.json states the argument in SECONDS; the library's window is milliseconds.
  const noticeWindowMs =
    args.noticeWindow === null ? SMILE_ID_SAMPLE_NOTICE_WINDOW_MS : args.noticeWindow * 1_000;

  // The five faces are bundled rather than fetched: a provider would make text depend on the network.
  const [fontsLoaded] = useFonts(smileFontAssets);

  useEffect(() => {
    void loadSettings();
  }, [loadSettings]);

  // The SDK's useColorScheme and the native bars read this, not the theme provider.
  useEffect(() => {
    if (settingsLoaded) Appearance.setColorScheme(dark ? 'dark' : 'light');
  }, [settingsLoaded, dark]);

  // Android re-applies the window's bars after a night-mode change, so ours go again.
  useEffect(() => {
    if (Platform.OS !== 'android') return undefined;
    const subscription = Appearance.addChangeListener(() =>
      requestAnimationFrame(() => reassertSystemBars(dark)),
    );
    return () => subscription.remove();
  }, [dark]);

  useEffect(() => {
    resetProfiles(smileIDSampleProfilesForLaunch(args));
    // Before the verifications route's first load, or its own read wins and the list opens empty.
    // Caught, not voided: a failed write must degrade to an empty list, never an unhandled rejection.
    if (args.seedJobs) seedFixtures(Date.now()).catch(() => undefined);
  }, [args, resetProfiles, seedFixtures]);

  if (!fontsLoaded) {
    return <View style={{ backgroundColor: colors.background, flex: 1 }} />;
  }

  return (
    <SafeAreaProvider>
      <UseSmileIDSampleThemeProvider dark={dark}>
        <UseSmileIDSampleNoticeWindowProvider value={noticeWindowMs}>
          <StatusBar style={dark ? 'light' : 'dark'} />
          {/* Names the button colour, as StatusBar does, despite the type's doc saying the bar's. */}
          <NavigationBar style={dark ? 'light' : 'dark'} />
          <Stack
            screenOptions={{
              headerShown: false,
              contentStyle: { backgroundColor: colors.background },
            }}
          >
            {/* Transparent, so products stays visible behind the sheet rather than being replaced. */}
            <Stack.Screen
              name="(products)/profiles/switch"
              options={{
                presentation: 'transparentModal',
                animation: 'none',
                contentStyle: { backgroundColor: 'transparent' },
              }}
            />
          </Stack>
        </UseSmileIDSampleNoticeWindowProvider>
      </UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>
  );
}
