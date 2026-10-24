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

import { UseSmileIDSampleProfileConfigStep } from '../src/steps/use-smile-id-sample-profile-config-step';
import { FakeNjiaCalls, type FakeNjiaNavigator } from '@smileid/njia-testing';

import { smileIDSampleFakeScope } from './support/use-smile-id-sample-test-njia';

jest.mock('react-native-safe-area-context', () => ({
  useSafeAreaInsets: () => ({ top: 24, bottom: 48, left: 0, right: 0 }),
}));

/// The page's scope, made fresh for each test, and its navigator, which records what the page asked for.
let opened: { scope: ReturnType<typeof smileIDSampleFakeScope>['scope']; navigator: FakeNjiaNavigator };

/// The profile page step, opened on the second fixture profile.
const ProfileConfig = () => <UseSmileIDSampleProfileConfigStep scope={opened.scope} />;

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
  opened = smileIDSampleFakeScope('profileConfig', { arg: 'p-2' });
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
    opened.navigator.expect(FakeNjiaCalls.back);
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
