import type { UseSmileIDSampleTokenSession } from '@smileid/sample-ui';
import { render, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';
import { useEffect } from 'react';

import RootLayout from '../app/_layout';
import { useSmileIDSampleShellExtension } from '../src/extension';
import { smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';

/// Every extension member the shell reached, in order.
const mockCalls: string[] = [];

jest.mock('../src/extension', () => ({
  useSmileIDSampleShellExtension: {
    onLaunch: (url: string | null) => mockCalls.push(`onLaunch ${url}`),
    launchSession: async () => {
      mockCalls.push('launchSession');
      return null as UseSmileIDSampleTokenSession | null;
    },
    debugRows: () => {
      mockCalls.push('debugRows');
      return null;
    },
    customiseFlow: () => mockCalls.push('customiseFlow'),
  },
}));
jest.mock('expo-linking', () => ({ getInitialURL: jest.fn() }));
jest.mock('expo-font', () => ({ useFonts: () => [true] }));
jest.mock('expo-status-bar', () => ({ StatusBar: () => null, setStatusBarStyle: () => undefined }));
jest.mock('expo-navigation-bar', () => {
  const NavigationBar = () => null;
  NavigationBar.setStyle = () => undefined;
  return { NavigationBar };
});
jest.mock('react-native-safe-area-context', () => ({
  SafeAreaProvider: ({ children }: { children?: unknown }) => children,
  useSafeAreaInsets: () => ({ top: 0, bottom: 0, left: 0, right: 0 }),
}));
/// Held for the router mock, which may only reach mock* names.
const mockReact = { useEffect };
/// The first screen the stack draws, reaching the extension in its render and in its first effect.
const mockScreen = () => {
  useSmileIDSampleShellExtension?.debugRows?.();
  mockReact.useEffect(() => {
    useSmileIDSampleShellExtension?.customiseFlow?.({} as never, 'biometricKyc' as never);
  }, []);
  return null;
};
jest.mock('expo-router', () => {
  const Stack = () => {
    const Screen = mockScreen;
    return <Screen />;
  };
  Stack.Screen = function StackScreen() {
    return null;
  };
  const router = { push: jest.fn(), back: jest.fn(), replace: jest.fn() };
  return {
    Stack,
    router,
    useRouter: () => router,
    usePathname: () => '/',
    useRootNavigationState: () => ({ key: 'root' }),
  };
});

const getInitialURL = Linking.getInitialURL as jest.MockedFunction<typeof Linking.getInitialURL>;

beforeEach(() => {
  mockCalls.length = 0;
  smileIDSampleResetLaunchArgs();
});

it('runs onLaunch before any screen reaches the extension, and the launch session after it', async () => {
  const link = 'usesmileid-sample-expo://settings?e2eScenario=x';
  getInitialURL.mockResolvedValue(link);
  await render(<RootLayout />);
  await waitFor(() => expect(mockCalls).toContain('launchSession'));

  expect(mockCalls[0]).toBe(`onLaunch ${link}`);
  expect(mockCalls.filter((call) => call.startsWith('onLaunch'))).toHaveLength(1);
});
