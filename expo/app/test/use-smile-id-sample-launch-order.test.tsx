import type { UseSmileIDSampleTokenSession } from '@smileid/sample-ui';
import { render, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';
import { Component, type ReactNode, useEffect } from 'react';

import { useSmileIDSampleShellExtension } from '../src/extension';
import { UseSmileIDSampleApp as RootLayout } from '../src/use-smile-id-sample-app';
import { smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';

/// Every extension member the shell reached, in order.
const mockCalls: string[] = [];
/// What onLaunch throws, if anything.
let mockFailure: Error | null = null;

jest.mock('../src/extension', () => ({
  useSmileIDSampleShellExtension: {
    onLaunch: (url: string | null) => {
      if (mockFailure) throw mockFailure;
      mockCalls.push(`onLaunch ${url}`);
    },
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
/// Held for the shell mock, which may only reach mock* names.
const mockReact = { useEffect };
/// The first screen the shell draws, reaching the extension in its render and in its first effect.
const mockScreen = () => {
  useSmileIDSampleShellExtension?.debugRows?.();
  mockReact.useEffect(() => {
    useSmileIDSampleShellExtension?.customiseFlow?.({} as never, 'biometricKyc' as never);
  }, []);
  return null;
};
jest.mock('../src/navigation/use-smile-id-sample-shell', () => ({
  UseSmileIDSampleShell: function Shell() {
    const Screen = mockScreen;
    return <Screen />;
  },
  smileIDSampleStartShell: () => undefined,
  smileIDSampleCurrentLink: () => null,
  smileIDSampleOpenLink: () => undefined,
}));

const getInitialURL = Linking.getInitialURL as jest.MockedFunction<typeof Linking.getInitialURL>;

beforeEach(() => {
  mockCalls.length = 0;
  mockFailure = null;
  smileIDSampleResetLaunchArgs();
});

/// Keeps what the root threw while rendering.
class Caught extends Component<{ children: ReactNode; onError: (error: Error) => void }, { failed: boolean }> {
  state = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  componentDidCatch(error: Error) {
    this.props.onError(error);
  }

  render() {
    return this.state.failed ? null : this.props.children;
  }
}

it('runs onLaunch before any screen reaches the extension, and the launch session after it', async () => {
  const link = 'usesmileid-sample-expo://settings?e2eScenario=x';
  getInitialURL.mockResolvedValue(link);
  await render(<RootLayout />);
  await waitFor(() => expect(mockCalls).toContain('launchSession'));

  expect(mockCalls[0]).toBe(`onLaunch ${link}`);
  expect(mockCalls.filter((call) => call.startsWith('onLaunch'))).toHaveLength(1);
});

it('raises a throw from onLaunch as a render error, before any screen reaches the extension', async () => {
  mockFailure = new Error('not a bundled scenario');
  const errors: Error[] = [];
  jest.spyOn(console, 'error').mockImplementation(() => undefined);
  getInitialURL.mockResolvedValue('usesmileid-sample-expo://?e2eScenario=typo');
  await render(
    <Caught onError={(error) => errors.push(error)}>
      <RootLayout />
    </Caught>,
  );
  await waitFor(() => expect(errors.map((error) => error.message)).toEqual(['not a bundled scenario']));

  expect(mockCalls).toEqual([]);
});
