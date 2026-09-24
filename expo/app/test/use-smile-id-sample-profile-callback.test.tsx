import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  UseSmileIDSampleTestIds,
  UseSmileIDSampleThemeProvider,
  smileIDSampleBase64UrlEncode,
  smileIDSampleFixtureProfiles,
  smileIDSampleTokenSession,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { act, fireEvent, render } from '@testing-library/react-native';

import ProfileConfig from '../app/profiles/[profileId]';

jest.mock('react-native-safe-area-context', () => ({
  useSafeAreaInsets: () => ({ top: 24, bottom: 48, left: 0, right: 0 }),
}));
const mockRouter = { back: jest.fn(), replace: jest.fn(), push: jest.fn(), canGoBack: () => true };
jest.mock('expo-router', () => ({
  useRouter: () => mockRouter,
  useLocalSearchParams: () => ({ profileId: 'p-2' }),
}));

/// A live session whose token binds `payload` as given.
const liveSession = (payload: string) => {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const claims = `{"iat":${nowSeconds - 1},"exp":${nowSeconds + 900},"api_url":"https://testapi.smileidentity.com/v3","payload":${payload}}`;
  return smileIDSampleTokenSession(['{"alg":"none"}', claims, 's'].map(smileIDSampleBase64UrlEncode).join('.'))!;
};

const page = async () =>
  await render(
    <UseSmileIDSampleThemeProvider dark={false}>
      <ProfileConfig />
    </UseSmileIDSampleThemeProvider>,
  );

beforeEach(async () => {
  await AsyncStorage.clear();
  useSmileIDSampleSessionStore.getState().reset();
  useSmileIDSampleProfileStore.getState().reset(smileIDSampleFixtureProfiles());
});

describe('a profile callback URL', () => {
  it('is saved trimmed with the details, and becomes the active profile', async () => {
    const screen = await page();
    await act(async () => {
      fireEvent.changeText(
        screen.getByTestId(UseSmileIDSampleTestIds.PROFILE_CONFIG_CALLBACK_URL),
        '  https://kazi.example/hooks ',
      );
    });
    await act(async () => {
      fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE));
    });
    const { items, activeId } = useSmileIDSampleProfileStore.getState();
    expect(activeId).toBe('p-2');
    expect(items.find((item) => item.id === 'p-2')?.callbackUrl).toBe('https://kazi.example/hooks');
  });

  it('gives way to a live session, and says whose URL applies', async () => {
    await useSmileIDSampleSessionStore.getState().link(liveSession('{"callback_url":"https://token.example"}'));
    const screen = await page();
    const row = screen.getByTestId(UseSmileIDSampleTestIds.PROFILE_CONFIG_CALLBACK_URL);
    expect(row.props.editable).toBe(false);
    expect(row.props.placeholder).toBe('Set by the scanned token');
  });

  it("names the token's partner default when the token binds no URL", async () => {
    await useSmileIDSampleSessionStore.getState().link(liveSession('{}'));
    const screen = await page();
    expect(screen.getByTestId(UseSmileIDSampleTestIds.PROFILE_CONFIG_CALLBACK_URL).props.placeholder).toBe(
      "The scanned token's partner default applies",
    );
  });
});
