import AsyncStorage from '@react-native-async-storage/async-storage';

import { UseSmileIDSampleSetting } from '../src/model/use-smile-id-sample-setting';
import { useSmileIDSampleSettingsStore } from '../src/state/use-smile-id-sample-settings-store';

const store = () => useSmileIDSampleSettingsStore.getState();

beforeEach(async () => {
  await AsyncStorage.clear();
  store().reset();
});

afterEach(() => jest.restoreAllMocks());

describe('the load window', () => {
  it('keeps a switch moved while the stored values were being read', async () => {
    await AsyncStorage.setItem('sample.setting.darkMode', 'false');
    let answer: () => void = () => undefined;
    const read = AsyncStorage.multiGet.bind(AsyncStorage);
    // The read takes its values now and answers later, which is the window a toggle can land in.
    jest.spyOn(AsyncStorage, 'multiGet').mockImplementationOnce((keys) => {
      const taken = read(keys);
      return new Promise((resolve) => (answer = () => void taken.then(resolve)));
    });
    const loading = store().load();
    await store().setSetting(UseSmileIDSampleSetting.DarkMode, true);
    answer();
    await loading;
    expect(store().loaded).toBe(true);
    expect(store().settings.darkMode).toBe(true);
  });

  it('reports loaded with the defaults when storage cannot be read', async () => {
    jest.spyOn(AsyncStorage, 'multiGet').mockRejectedValueOnce(new Error('disk'));
    await store().load();
    expect(store().loaded).toBe(true);
  });
});
