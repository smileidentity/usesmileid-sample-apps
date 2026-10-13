import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  SMILE_ID_SAMPLE_NOTICE_WINDOW_MS,
  UseSmileIDSampleThemeProvider,
  UseSmileIDSampleTransientNoticeHost,
  useSmileIDSampleJobStore,
  useSmileIDSampleTransientNotice,
  useSmileIDSampleSettingsStore,
  useSmileIDSampleTheme,
  useSmileIDSampleProfileStore,
} from '@smileid/sample-ui';
import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';
import { BottomTabBarHeightContext } from 'expo-router/tabs';
import { useEffect } from 'react';
import { Appearance, Platform, Text, useColorScheme } from 'react-native';

import Verifications from '../app/(tabs)/verifications';
import RootLayout from '../app/_layout';
import { useSmileIDSampleDeviceScheme } from '../src/use-smile-id-sample-device-scheme';
import { smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';

jest.mock('expo-linking', () => ({ getInitialURL: jest.fn() }));
jest.mock('react-native/Libraries/Utilities/useColorScheme');
jest.mock('expo-font', () => ({ useFonts: () => [true] }));
/// The style each StatusBar mount asked for.
const mockStatusBarStyles: string[] = [];
/// The style each imperative re-assert sent, which is what Android's night-mode change is answered with.
const mockStatusBarReasserts: string[] = [];
jest.mock('expo-status-bar', () => ({
  StatusBar: function StatusBar({ style }: { style: string }) {
    mockStatusBarStyles.push(style);
    return null;
  },
  setStatusBarStyle: (style: string) => mockStatusBarReasserts.push(style),
}));
/// The style each NavigationBar mount asked for; like StatusBar's, it names the button colour.
const mockNavigationBarStyles: string[] = [];
/// The navigation bar's imperative re-asserts, in order.
const mockNavigationBarReasserts: string[] = [];
jest.mock('expo-navigation-bar', () => {
  function NavigationBar({ style }: { style: string }) {
    mockNavigationBarStyles.push(style);
    return null;
  }
  NavigationBar.setStyle = (style: string) => mockNavigationBarReasserts.push(style);
  return { NavigationBar };
});
// Without pinned metrics the real provider withholds its children until it has measured, so nothing renders.
jest.mock('react-native-safe-area-context', () => ({
  SafeAreaProvider: function SafeAreaProvider({ children }: { children?: unknown }) {
    return children;
  },
  useSafeAreaInsets: () => ({ top: 44, bottom: 34, left: 0, right: 0 }),
}));
// The router owns navigation; the stand-in renders the probe, which reads the theme from inside the provider.
/// Held for the router mock: a hook must be named use*, and jest only lets a factory reach a mock*.
const mockReact = { useEffect };

jest.mock('expo-router', () => {
  // One instance, not one per render: a component keying an effect on the router would loop.
  const router = { push: jest.fn(), back: jest.fn(), replace: jest.fn() };
  const useRouter = () => router;
  function Stack() {
    const Probe = mockProbe;
    return <Probe />;
  }
  Stack.Screen = function StackScreen() {
    return null;
  };
  // Runs the effect and its cleanup as the real one does, so the focus teardown is not stubbed inert.
  const useFocusEffect = (effect: () => void | (() => void)) =>
    mockReact.useEffect(effect, [effect]);
  const usePathname = () => '/';
  return { Stack, useRouter, usePathname, useFocusEffect };
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

/// Whatever the router would have rendered, so a test can observe the tree from inside every provider.
let mockProbe: () => React.ReactElement;

/// Reads the theme the provider actually resolved, rather than inferring it from a colour.
const SchemeProbe = () => (
  <Text testID="scheme">{useSmileIDSampleTheme().dark ? 'dark' : 'light'}</Text>
);

/// Shows one notice on mount and hosts it, so the auto-dismiss window is the thing under test.
const NoticeProbe = () => {
  const notice = useSmileIDSampleTransientNotice();
  const { show } = notice;
  useEffect(() => {
    show({ message: '1 verification hidden from App list' });
  }, [show]);
  return <UseSmileIDSampleTransientNoticeHost state={notice} />;
};

const resolvedScheme = async ({
  appearance,
  legacyDarkMode,
  system,
}: {
  appearance?: 'system' | 'light' | 'dark';
  legacyDarkMode?: boolean;
  system: 'light' | 'dark';
}) => {
  systemScheme.mockReturnValue(system);
  // Seeded in storage, not in the store: the root's own load() runs and would overwrite a set state.
  if (appearance !== undefined) await AsyncStorage.setItem('sample.setting.appearance', appearance);
  if (legacyDarkMode !== undefined) {
    await AsyncStorage.setItem('sample.setting.darkMode', String(legacyDarkMode));
  }
  getInitialURL.mockResolvedValue(null);
  const { getByTestId } = await render(<RootLayout />);
  await waitFor(() => expect(useSmileIDSampleSettingsStore.getState().loaded).toBe(true));
  return getByTestId('scheme');
};

/// What the root imposed through Appearance.
let imposedScheme: jest.SpyInstance;

beforeEach(async () => {
  smileIDSampleResetLaunchArgs();
  mockProbe = SchemeProbe;
  mockStatusBarStyles.length = 0;
  mockNavigationBarStyles.length = 0;
  mockStatusBarReasserts.length = 0;
  mockNavigationBarReasserts.length = 0;
  imposedScheme = jest.spyOn(Appearance, 'setColorScheme').mockImplementation(() => undefined);
  await AsyncStorage.clear();
  useSmileIDSampleJobStore.getState().reset();
  useSmileIDSampleSettingsStore.getState().reset();
  systemScheme.mockReturnValue('light');
});

// Patched on the real module, so restored before the next file runs.
afterEach(() => {
  imposedScheme.mockRestore();
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

  it('builds the profile store once, from the link rather than the defaults before it', async () => {
    useSmileIDSampleProfileStore.setState({ loaded: false });
    const reset = jest.spyOn(useSmileIDSampleProfileStore.getState(), 'reset');
    await launch(`${LAUNCH}?seedProfiles=true`);
    await waitFor(() => expect(reset).toHaveBeenCalled());
    expect(reset).toHaveBeenCalledTimes(1);
    expect(useSmileIDSampleProfileStore.getState().items.length).toBeGreaterThan(1);
    reset.mockRestore();
  });

  it('seeds nothing on a plain cold start, so a partner sees only their own data', async () => {
    await launch(null);
    expect(jobs()).toEqual([]);
  });
});

describe('the appearance reaches the theme and the system bars', () => {
  it('pins a light device dark when Dark is chosen', async () => {
    expect(await resolvedScheme({ appearance: 'dark', system: 'light' })).toHaveTextContent('dark');
    expect(imposedScheme).toHaveBeenLastCalledWith('dark');
    expect(mockStatusBarStyles.at(-1)).toBe('light');
    expect(mockNavigationBarStyles.at(-1)).toBe('light');
  });

  it('pins a dark device light when Light is chosen, as Android and iOS do', async () => {
    expect(await resolvedScheme({ appearance: 'light', system: 'dark' })).toHaveTextContent('light');
    expect(imposedScheme).toHaveBeenLastCalledWith('light');
    expect(mockStatusBarStyles.at(-1)).toBe('dark');
    expect(mockNavigationBarStyles.at(-1)).toBe('dark');
  });

  it('follows a dark device on a fresh install and hands the scheme back with unspecified', async () => {
    expect(await resolvedScheme({ system: 'dark' })).toHaveTextContent('dark');
    expect(imposedScheme).toHaveBeenLastCalledWith('unspecified');
    expect(mockStatusBarStyles.at(-1)).toBe('light');
  });

  it('reads the released Dark mode switch turned on as Dark', async () => {
    expect(await resolvedScheme({ legacyDarkMode: true, system: 'light' })).toHaveTextContent('dark');
    expect(imposedScheme).toHaveBeenLastCalledWith('dark');
  });

  it('reads the released switch turned off as System, since off was also its default', async () => {
    expect(await resolvedScheme({ legacyDarkMode: false, system: 'dark' })).toHaveTextContent('dark');
    expect(imposedScheme).toHaveBeenLastCalledWith('unspecified');
  });

  it("keeps the device's own theme for the System label while the app pins the other", async () => {
    useSmileIDSampleDeviceScheme.setState({ deviceDark: false });
    expect(await resolvedScheme({ appearance: 'light', system: 'dark' })).toHaveTextContent('light');
    expect(useSmileIDSampleDeviceScheme.getState().deviceDark).toBe(true);
  });

  it("re-asserts Android's bars with the event's theme under System, not the one it subscribed with", async () => {
    const os = jest.replaceProperty(Platform, 'OS', 'android');
    const listeners: ((preferences: { colorScheme: 'light' | 'dark' }) => void)[] = [];
    const subscribe = jest.spyOn(Appearance, 'addChangeListener').mockImplementation((listener) => {
      listeners.push(listener as (preferences: { colorScheme: 'light' | 'dark' }) => void);
      return { remove: () => undefined } as ReturnType<typeof Appearance.addChangeListener>;
    });
    try {
      expect(await resolvedScheme({ system: 'light' })).toHaveTextContent('light');
      await act(async () => {
        listeners.at(-1)?.({ colorScheme: 'dark' });
        await new Promise((resolve) => requestAnimationFrame(resolve));
      });
      expect(mockStatusBarReasserts.at(-1)).toBe('light');
      expect(mockNavigationBarReasserts.at(-1)).toBe('light');
    } finally {
      subscribe.mockRestore();
      os.restore();
    }
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

describe('noticeWindow decides how long a transient notice stays', () => {
  const showNotice = async (url: string | null) => {
    mockProbe = NoticeProbe;
    getInitialURL.mockResolvedValue(url);
    const screen = await render(<RootLayout />);
    // Flushed, not awaited: waitFor advances fake timers in steps and would eat part of the window.
    await act(async () => {});
    expect(screen.queryByText(/hidden from App list/)).not.toBeNull();
    return screen;
  };

  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('holds the notice for the window the launch asked for, to the second', async () => {
    // 60 SECONDS. Read as milliseconds it is 60ms, and the notice is gone long before the first edge.
    const screen = await showNotice(`${LAUNCH}?noticeWindow=60`);
    await act(async () => {
      jest.advanceTimersByTime(60_000 - 1);
    });
    expect(screen.queryByText(/hidden from App list/)).not.toBeNull();

    await act(async () => {
      jest.advanceTimersByTime(2);
    });
    expect(screen.queryByText(/hidden from App list/)).toBeNull();
  });

  it('falls back to the product\'s own window when the launch says nothing', async () => {
    const screen = await showNotice(null);
    await act(async () => {
      jest.advanceTimersByTime(SMILE_ID_SAMPLE_NOTICE_WINDOW_MS + 1);
    });
    expect(screen.queryByText(/hidden from App list/)).toBeNull();
  });
});

describe('hiding a verification is confirmed and can be undone', () => {
  const renderList = async () => {
    await useSmileIDSampleJobStore.getState().seedFixtures(Date.now());
    return render(
      <UseSmileIDSampleThemeProvider dark={false}>
        <BottomTabBarHeightContext.Provider value={100}>
          <Verifications />
        </BottomTabBarHeightContext.Provider>
      </UseSmileIDSampleThemeProvider>,
    );
  };

  it('confirms the removal and puts the row back when Undo is pressed', async () => {
    const screen = await renderList();
    const before = useSmileIDSampleJobStore.getState().jobs ?? [];
    expect(before.length).toBeGreaterThan(0);

    await act(async () => {
      await useSmileIDSampleJobStore.getState().remove([before[0]!.id]);
    });
    await waitFor(() => expect(screen.queryByText('1 verification hidden from App list')).not.toBeNull());
    expect(useSmileIDSampleJobStore.getState().jobs).toHaveLength(before.length - 1);

    await act(async () => {
      fireEvent.press(screen.getByText('Undo'));
    });
    await waitFor(() =>
      expect(useSmileIDSampleJobStore.getState().jobs).toHaveLength(before.length),
    );
  });

  it('consumes the confirmation on sight, so returning cannot replay one already acted on', async () => {
    const screen = await renderList();
    const before = useSmileIDSampleJobStore.getState().jobs ?? [];
    await act(async () => {
      await useSmileIDSampleJobStore.getState().remove([before[0]!.id]);
    });
    await waitFor(() => expect(screen.queryByText('1 verification hidden from App list')).not.toBeNull());
    expect(useSmileIDSampleJobStore.getState().removals).toEqual([]);
  });
});
