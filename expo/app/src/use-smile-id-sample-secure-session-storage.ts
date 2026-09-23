import type { UseSmileIDSampleSessionStorage } from '@smileid/sample-ui';
import * as SecureStore from 'expo-secure-store';

/// Not an application id, so it stays identity-agnostic across the hosts that run this shell's library.
const KEY = 'usesmileid_sample_token_session';

/// The token is a bearer credential, so it lives in the Keychain or Keystore, never beside the switches; device-only as on iOS.
export const smileIDSampleSecureSessionStorage: UseSmileIDSampleSessionStorage = {
  read: () => SecureStore.getItemAsync(KEY),
  write: (value) =>
    value === null
      ? SecureStore.deleteItemAsync(KEY)
      : SecureStore.setItemAsync(KEY, value, { keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY }),
};
