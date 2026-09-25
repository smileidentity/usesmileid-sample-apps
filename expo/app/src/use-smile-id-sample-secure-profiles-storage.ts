import AsyncStorage from '@react-native-async-storage/async-storage';
import { SMILE_ID_SAMPLE_PROFILES_KEY, type UseSmileIDSampleProfilesStorage } from '@smileid/sample-ui';
import * as SecureStore from 'expo-secure-store';

const options = { keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY };

/// The profiles in the Keychain or Keystore, device-only, since they hold people's details.
export const smileIDSampleSecureProfilesStorage: UseSmileIDSampleProfilesStorage = {
  read: async () => {
    const sealed = await SecureStore.getItemAsync(SMILE_ID_SAMPLE_PROFILES_KEY, options);
    if (sealed !== null) return sealed;
    // A plain record from before moves across once, and leaves AsyncStorage.
    const plain = await AsyncStorage.getItem(SMILE_ID_SAMPLE_PROFILES_KEY);
    if (plain !== null) {
      await SecureStore.setItemAsync(SMILE_ID_SAMPLE_PROFILES_KEY, plain, options);
      await AsyncStorage.removeItem(SMILE_ID_SAMPLE_PROFILES_KEY);
    }
    return plain;
  },
  write: (value) =>
    value === null
      ? SecureStore.deleteItemAsync(SMILE_ID_SAMPLE_PROFILES_KEY, options)
      : SecureStore.setItemAsync(SMILE_ID_SAMPLE_PROFILES_KEY, value, options),
};
