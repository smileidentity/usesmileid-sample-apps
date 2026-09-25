import { fireEvent } from '@testing-library/react-native';
import { Alert, type AlertButton } from 'react-native';

import { ProfileConfigScreen } from '../src/screens/profile-config-screen';
import { SettingsScreen } from '../src/screens/settings-screen';
import { smileIDSampleSettingsDefaults } from '../src/state/use-smile-id-sample-settings';
import { smileIDSampleUserDetailsDefaults } from '../src/state/use-smile-id-sample-profiles';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { renderInTheme } from './render-in-theme';

const noop = () => {};

const lastAlertButtons = (alert: jest.SpyInstance): AlertButton[] => alert.mock.calls.at(-1)?.[2] ?? [];

afterEach(() => jest.restoreAllMocks());

describe('sign-out', () => {
  it('asks first, and only the destructive button signs out', async () => {
    const alert = jest.spyOn(Alert, 'alert').mockImplementation(noop);
    const signOut = jest.fn();
    const rendered = await renderInTheme(
      <SettingsScreen
        state={{ settings: smileIDSampleSettingsDefaults, organisation: 'Kobo', initials: 'AO', versionLabel: 'Smile ID · 1.0.0' }}
        onSettingChange={noop}
        onProfilePress={noop}
        onNavRowPress={noop}
        onSignOut={signOut}
      />,
      false,
    );

    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.SIGN_OUT));
    expect(signOut).not.toHaveBeenCalled();

    const [cancel, confirm] = lastAlertButtons(alert);
    cancel?.onPress?.();
    expect(signOut).not.toHaveBeenCalled();
    expect(confirm?.style).toBe('destructive');
    confirm?.onPress?.();
    expect(signOut).toHaveBeenCalledTimes(1);
  });
});

describe('deleting a profile', () => {
  it('asks first, and only the destructive button deletes', async () => {
    const alert = jest.spyOn(Alert, 'alert').mockImplementation(noop);
    const remove = jest.fn();
    const rendered = await renderInTheme(
      <ProfileConfigScreen
        state={{
          title: 'Kobo',
          organisation: 'Kobo',
          defaults: smileIDSampleUserDetailsDefaults,
          isActive: true,
          callbackUrl: '',
          callbackOverride: null,
        }}
        onFieldChange={noop}
        onCallbackUrlChange={noop}
        onBack={noop}
        onSave={noop}
        onDelete={remove}
      />,
      false,
    );

    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.PROFILE_CONFIG_DELETE));
    expect(remove).not.toHaveBeenCalled();

    const [cancel, confirm] = lastAlertButtons(alert);
    cancel?.onPress?.();
    expect(remove).not.toHaveBeenCalled();
    confirm?.onPress?.();
    expect(remove).toHaveBeenCalledTimes(1);
  });
});
