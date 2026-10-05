import AsyncStorage from '@react-native-async-storage/async-storage';

import { UseSmileIDSampleAppearance } from '../src/model/use-smile-id-sample-appearance';
import { UseSmileIDSampleCaptureMode } from '../src/model/use-smile-id-sample-capture-mode';
import { smileIDSampleSettingsDefaults } from '../src/state/use-smile-id-sample-settings';
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
    await AsyncStorage.setItem('sample.setting.previewStep', 'true');
    let answer: () => void = () => undefined;
    const read = AsyncStorage.multiGet.bind(AsyncStorage);
    // The read takes its values now and answers later, which is the window a toggle can land in.
    jest.spyOn(AsyncStorage, 'multiGet').mockImplementationOnce((keys) => {
      const taken = read(keys);
      return new Promise((resolve) => (answer = () => void taken.then(resolve)));
    });
    const loading = store().load();
    await store().setSetting(UseSmileIDSampleSetting.PreviewStep, false);
    answer();
    await loading;
    expect(store().loaded).toBe(true);
    expect(store().settings.previewStep).toBe(false);
  });

  it('keeps an appearance chosen while the stored values were being read', async () => {
    await AsyncStorage.setItem('sample.setting.appearance', 'light');
    let answer: () => void = () => undefined;
    const read = AsyncStorage.multiGet.bind(AsyncStorage);
    jest.spyOn(AsyncStorage, 'multiGet').mockImplementationOnce((keys) => {
      const taken = read(keys);
      return new Promise((resolve) => (answer = () => void taken.then(resolve)));
    });
    const loading = store().load();
    await store().setAppearance(UseSmileIDSampleAppearance.Dark);
    answer();
    await loading;
    expect(store().settings.appearance).toBe(UseSmileIDSampleAppearance.Dark);
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

  it('keep the skip and order switches across a reload', async () => {
    await store().setSetting(UseSmileIDSampleSetting.AllowSkipBack, true);
    await store().setSetting(UseSmileIDSampleSetting.SelfieFirst, true);

    store().reset();
    await store().load();
    expect(store().settings.allowSkipBack).toBe(true);
    expect(store().settings.selfieFirst).toBe(true);
  });

  it('read an unknown stored capture mode as the default', async () => {
    await AsyncStorage.setItem('sample.setting.captureMode', 'sometimes');
    await store().load();
    expect(store().settings.captureMode).toBe(UseSmileIDSampleCaptureMode.AutoWithFallback);
  });
});

describe('the appearance', () => {
  const loadWith = async (stored: Record<string, string>) => {
    await AsyncStorage.multiSet(Object.entries(stored));
    await store().load();
    return store().settings.appearance;
  };

  it('follows the device when nothing is stored', async () => {
    expect(await loadWith({})).toBe(UseSmileIDSampleAppearance.System);
  });

  it('reads the released Dark mode switch turned on as Dark', async () => {
    expect(await loadWith({ 'sample.setting.darkMode': 'true' })).toBe(UseSmileIDSampleAppearance.Dark);
  });

  it('reads the released switch turned off as System, since off was also its default', async () => {
    expect(await loadWith({ 'sample.setting.darkMode': 'false' })).toBe(UseSmileIDSampleAppearance.System);
  });

  // Also the state a crash between the two writes leaves behind.
  it('takes a stored id over the released switch', async () => {
    expect(
      await loadWith({ 'sample.setting.appearance': 'light', 'sample.setting.darkMode': 'true' }),
    ).toBe(UseSmileIDSampleAppearance.Light);
  });

  it('reads an unknown id as System', async () => {
    expect(await loadWith({ 'sample.setting.appearance': 'sepia' })).toBe(UseSmileIDSampleAppearance.System);
  });

  it('never spreads the released key onto the settings as a field of its own', async () => {
    await loadWith({ 'sample.setting.darkMode': 'false' });
    expect(store().settings).toEqual(smileIDSampleSettingsDefaults);
  });

  it('stores its id and retires the released switch', async () => {
    await AsyncStorage.setItem('sample.setting.darkMode', 'true');
    await store().setAppearance(UseSmileIDSampleAppearance.Light);
    expect(await AsyncStorage.getItem('sample.setting.appearance')).toBe('light');
    expect(await AsyncStorage.getItem('sample.setting.darkMode')).toBeNull();

    store().reset();
    expect(await loadWith({})).toBe(UseSmileIDSampleAppearance.Light);
  });
});
