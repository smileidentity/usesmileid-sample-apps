import AsyncStorage from '@react-native-async-storage/async-storage';

import { UseSmileIDSampleCaptureMode } from '../src/model/use-smile-id-sample-capture-mode';
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

describe('the document capture settings', () => {
  it('keep the capture mode and gallery upload across a reload', async () => {
    await store().setCaptureMode(UseSmileIDSampleCaptureMode.Manual);
    await store().setSetting(UseSmileIDSampleSetting.GalleryUpload, true);
    expect(await AsyncStorage.getItem('sample.setting.captureMode')).toBe('manual');

    store().reset();
    await store().load();
    expect(store().settings.captureMode).toBe(UseSmileIDSampleCaptureMode.Manual);
    expect(store().settings.galleryUpload).toBe(true);
  });

  it('keep the back side, skip and order switches across a reload', async () => {
    await store().setSetting(UseSmileIDSampleSetting.CaptureBothSides, false);
    await store().setSetting(UseSmileIDSampleSetting.AllowSkipBack, true);
    await store().setSetting(UseSmileIDSampleSetting.SelfieFirst, true);

    store().reset();
    await store().load();
    expect(store().settings.captureBothSides).toBe(false);
    expect(store().settings.allowSkipBack).toBe(true);
    expect(store().settings.selfieFirst).toBe(true);
  });

  it('read an unknown stored capture mode as the default', async () => {
    await AsyncStorage.setItem('sample.setting.captureMode', 'sometimes');
    await store().load();
    expect(store().settings.captureMode).toBe(UseSmileIDSampleCaptureMode.AutoWithFallback);
  });
});
