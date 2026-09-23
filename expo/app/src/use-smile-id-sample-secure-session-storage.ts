import type { UseSmileIDSampleSessionStorage } from '@smileid/sample-ui';
import * as SecureStore from 'expo-secure-store';

/// The item Flutter's secure store uses.
const KEY = 'token_session';

/// The token session in the Keychain or Keystore, device-only as on iOS.
export const smileIDSampleSecureSessionStorage: UseSmileIDSampleSessionStorage = {
  read: () => SecureStore.getItemAsync(KEY),
  write: (value) =>
    value === null
      ? SecureStore.deleteItemAsync(KEY)
      : SecureStore.setItemAsync(KEY, value, { keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY }),
};
