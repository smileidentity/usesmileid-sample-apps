import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  useSmileIDSampleJobStore,
  useSmileIDSampleSettingsStore,
  useSmileIDSampleTheme,
} from '@smileid/sample-ui';
import { act, render, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';
import { Text, useColorScheme } from 'react-native';

import RootLayout from '../app/_layout';

jest.mock('expo-linking', () => ({ getInitialURL: jest.fn() }));
jest.mock('react-native/Libraries/Utilities/useColorScheme');
jest.mock('expo-font', () => ({ useFonts: () => [true] }));
jest.mock('expo-status-bar', () => ({ StatusBar: function StatusBar() { return null; } }));
// Without pinned metrics the real provider withholds its children until it has measured, so nothing renders.
jest.mock('react-native-safe-area-context', () => ({
  SafeAreaProvider: function SafeAreaProvider({ children }: { children?: unknown }) {
    return children;
  },
  useSafeAreaInsets: () => ({ top: 44, bottom: 34, left: 0, right: 0 }),
}));
// The router owns navigation; the stand-in renders the probe, which reads the theme from inside the provider.
jest.mock('expo-router', () => {
  function Stack() {
    return <MockSchemeProbe />;
  }
  Stack.Screen = function StackScreen() {
    return null;
  };
  return { Stack };
});

const getInitialURL = Linking.getInitialURL as jest.MockedFunction<typeof Linking.getInitialURL>;

/// The scheme spec/app-identity.json reserves for this app, which is what a cold start arrives on.
const LAUNCH = 'usesmileid-sample-expo://';

const launch = async (url: string | null) => {
  getInitialURL.mockResolvedValue(url);
  await render(<RootLayout />);
  await waitFor(() => expect(getInitialURL).toHaveBeenCalled());
  // Seeding is fire-and-forget, so a negative case has to outlast it or it asserts on an unfinished seed.
  await act(async () => {});
};

const jobs = () => useSmileIDSampleJobStore.getState().jobs ?? [];

const systemScheme = useColorScheme as jest.MockedFunction<typeof useColorScheme>;

/// Reads the theme the provider actually resolved, rather than inferring it from a colour.
const MockSchemeProbe = () => (
  <Text testID="scheme">{useSmileIDSampleTheme().dark ? 'dark' : 'light'}</Text>
);

const resolvedScheme = async ({
  darkMode,
  system,
}: {
  darkMode: boolean;
  system: 'light' | 'dark';
}) => {
  systemScheme.mockReturnValue(system);
  // Seeded in storage, not in the store: the root's own load() runs and would overwrite a set state.
  await AsyncStorage.setItem('sample.setting.darkMode', String(darkMode));
  getInitialURL.mockResolvedValue(null);
  const { getByTestId } = await render(<RootLayout />);
  await waitFor(() => expect(useSmileIDSampleSettingsStore.getState().loaded).toBe(true));
  return getByTestId('scheme');
};

beforeEach(async () => {
  await AsyncStorage.clear();
  useSmileIDSampleJobStore.getState().reset();
  useSmileIDSampleSettingsStore.getState().reset();
  systemScheme.mockReturnValue('light');
});

describe('seedJobs decides whether the verifications list has anything in it', () => {
  it('seeds the design fixtures when the launch carries the argument', async () => {
    await launch(`${LAUNCH}?seedJobs=true`);
    await waitFor(() => expect(jobs().length).toBeGreaterThan(0));
  });

  it('seeds nothing when the launch does not', async () => {
    await launch(`${LAUNCH}?seedProfiles=true`);
    await waitFor(() => expect(getInitialURL).toHaveBeenCalled());
    expect(jobs()).toEqual([]);
  });

  it('seeds nothing on a plain cold start, so a partner sees only their own data', async () => {
    await launch(null);
    expect(jobs()).toEqual([]);
  });
});

describe('the Dark Mode switch reaches the theme', () => {
  it('overrides a light device to dark when the switch is on', async () => {
    expect(await resolvedScheme({ darkMode: true, system: 'light' })).toHaveTextContent('dark');
  });

  it('follows a dark device when the switch is off, rather than forcing light', async () => {
    expect(await resolvedScheme({ darkMode: false, system: 'dark' })).toHaveTextContent('dark');
  });

  it('stays light when neither asks for dark', async () => {
    expect(await resolvedScheme({ darkMode: false, system: 'light' })).toHaveTextContent('light');
  });

  it('loads the stored settings at root, or the switch has nothing to read', async () => {
    const load = jest.spyOn(useSmileIDSampleSettingsStore.getState(), 'load');
    getInitialURL.mockResolvedValue(null);
    await render(<RootLayout />);
    await waitFor(() => expect(load).toHaveBeenCalled());
    // Installed on the live store action, so leaving it patched would follow every later test.
    load.mockRestore();
  });
});
