import {
  UseSmileIDSampleThemeProvider,
  smileDarkColors,
  smileFontAssets,
  smileIDSampleProfilesForLaunch,
  smileLightColors,
  useSmileIDSampleProfileStore,
} from '@smileid/sample-ui';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { useColorScheme, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { useLaunchArgs } from '../src/use-smile-id-sample-launch';

/// The navigation host. Every route is a file under app/, matching the expo column of spec/routes.json.
export default function RootLayout() {
  const scheme = useColorScheme();
  const dark = scheme === 'dark';
  const colors = dark ? smileDarkColors : smileLightColors;
  const args = useLaunchArgs();
  const resetProfiles = useSmileIDSampleProfileStore((state) => state.reset);

  // The five faces are bundled rather than fetched: a provider would make text depend on the network.
  const [fontsLoaded] = useFonts(smileFontAssets);

  useEffect(() => {
    resetProfiles(smileIDSampleProfilesForLaunch(args));
  }, [args, resetProfiles]);

  if (!fontsLoaded) {
    return <View style={{ backgroundColor: colors.background, flex: 1 }} />;
  }

  return (
    <SafeAreaProvider>
      <UseSmileIDSampleThemeProvider dark={dark}>
        <StatusBar style={dark ? 'light' : 'dark'} />
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: { backgroundColor: colors.background },
          }}
        />
      </UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>
  );
}
