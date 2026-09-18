import { useSmileIDSampleJobStore } from '@smileid/sample-ui';
import { act, render, waitFor } from '@testing-library/react-native';
import * as Linking from 'expo-linking';

import RootLayout from '../app/_layout';

jest.mock('expo-linking', () => ({ getInitialURL: jest.fn() }));
jest.mock('expo-font', () => ({ useFonts: () => [true] }));
jest.mock('expo-status-bar', () => ({ StatusBar: () => null }));
// The router owns navigation, which none of this wiring is about; passing children through renders the tree.
jest.mock('expo-router', () => {
  function Stack({ children }: { children?: unknown }) {
    return children;
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

beforeEach(() => {
  useSmileIDSampleJobStore.getState().reset();
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
