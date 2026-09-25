import AsyncStorage from '@react-native-async-storage/async-storage';

import { smileIDSampleSecureProfilesStorage } from '../src/use-smile-id-sample-secure-profiles-storage';

/// The Keychain or Keystore, held in memory for the test.
const mockKeychain = new Map<string, string>();
jest.mock('expo-secure-store', () => ({
  WHEN_UNLOCKED_THIS_DEVICE_ONLY: 'whenUnlockedThisDeviceOnly',
  getItemAsync: jest.fn(async (key: string) => mockKeychain.get(key) ?? null),
  setItemAsync: jest.fn(async (key: string, value: string) => {
    mockKeychain.set(key, value);
  }),
  deleteItemAsync: jest.fn(async (key: string) => {
    mockKeychain.delete(key);
  }),
}));

const record = '{"version":1,"activeId":"p-1","profiles":[{"id":"p-1","organisation":"Kobo","email":"ada@kobo.example"}]}';

beforeEach(async () => {
  mockKeychain.clear();
  await AsyncStorage.clear();
});

describe('the profiles store', () => {
  it('keeps the record in the secure store, never in AsyncStorage', async () => {
    await smileIDSampleSecureProfilesStorage.write(record);

    expect(mockKeychain.get('sample_profiles')).toBe(record);
    expect(await AsyncStorage.getItem('sample_profiles')).toBeNull();
    expect(await smileIDSampleSecureProfilesStorage.read()).toBe(record);
  });

  it('moves a plain record from before across once, and deletes it from AsyncStorage', async () => {
    await AsyncStorage.setItem('sample_profiles', record);

    expect(await smileIDSampleSecureProfilesStorage.read()).toBe(record);
    expect(mockKeychain.get('sample_profiles')).toBe(record);
    expect(await AsyncStorage.getItem('sample_profiles')).toBeNull();
  });

  it('reads an install holding only the released settings as no record, and leaves them', async () => {
    await AsyncStorage.setItem('sample.setting.darkMode', 'true');

    expect(await smileIDSampleSecureProfilesStorage.read()).toBeNull();
    expect(await AsyncStorage.getItem('sample.setting.darkMode')).toBe('true');
  });

  it('deletes the record on a null write', async () => {
    await smileIDSampleSecureProfilesStorage.write(record);
    await smileIDSampleSecureProfilesStorage.write(null);

    expect(mockKeychain.has('sample_profiles')).toBe(false);
  });
});
