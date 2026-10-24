import AsyncStorage from '@react-native-async-storage/async-storage';
import { UseSmileIDSampleLanguage, useSmileIDSampleSettingsStore } from '@smileid/sample-ui';
import { act, renderHook, waitFor } from '@testing-library/react-native';
import { reloadAppAsync } from 'expo';
import { I18nManager } from 'react-native';

import { smileIDSampleCatalogueLocale } from '../src/catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleAppLanguage } from '../src/use-smile-id-sample-app-language';

jest.mock('expo', () => ({ ...jest.requireActual('expo'), reloadAppAsync: jest.fn(async () => undefined) }));

let mockLocales = [{ languageTag: 'en-GB' }];
jest.mock('expo-localization', () => ({ useLocales: () => mockLocales, getLocales: () => mockLocales }));

/// The link of the screen showing, as the shell reports it.
let showing: string | null = 'settings';
const routing = { currentLink: () => showing, reopen: jest.fn() };

const RELOAD_KEY = 'usesmileid-sample.directionReload';
let rtl = false;

beforeAll(() => {
  Object.defineProperty(I18nManager, 'isRTL', { get: () => rtl, configurable: true });
});

beforeEach(async () => {
  rtl = false;
  showing = 'settings';
  routing.reopen.mockClear();
  mockLocales = [{ languageTag: 'en-GB' }];
  await AsyncStorage.clear();
  jest.spyOn(I18nManager, 'forceRTL').mockImplementation(() => undefined);
  jest.spyOn(I18nManager, 'allowRTL').mockImplementation(() => undefined);
  useSmileIDSampleSettingsStore.setState((state) => ({
    loaded: true,
    settings: { ...state.settings, language: UseSmileIDSampleLanguage.System },
  }));
});

const settle = () => act(async () => await new Promise((resolve) => setTimeout(resolve, 20)));

const pick = (language: UseSmileIDSampleLanguage) =>
  useSmileIDSampleSettingsStore.setState((state) => ({ settings: { ...state.settings, language } }));

describe('the app language', () => {
  it('reloads once into right to left, saving where the app was', async () => {
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, true, routing));
    await waitFor(() => expect(reloadAppAsync).toHaveBeenCalledTimes(1));
    expect(I18nManager.forceRTL).toHaveBeenCalledWith(true);
    expect(JSON.parse((await AsyncStorage.getItem(RELOAD_KEY))!)).toMatchObject({ direction: 'rtl', path: 'settings' });
  });

  it('does not reload again when a reload could not apply the direction', async () => {
    await AsyncStorage.setItem(RELOAD_KEY, JSON.stringify({ direction: 'rtl', path: '/settings', atMillis: Date.now() }));
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, true, routing));
    await settle();
    expect(I18nManager.forceRTL).not.toHaveBeenCalled();
    expect(reloadAppAsync).not.toHaveBeenCalled();
  });

  it('tries again on a later launch when an old reload could not apply the direction', async () => {
    await AsyncStorage.setItem(RELOAD_KEY, JSON.stringify({ direction: 'rtl', path: '/settings', atMillis: Date.now() - 120_000 }));
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, true, routing));
    await waitFor(() => expect(reloadAppAsync).toHaveBeenCalledTimes(1));
  });

  it('returns to the saved screen once the reload lands, rather than the replayed launch link', async () => {
    rtl = true;
    showing = 'products';
    await AsyncStorage.setItem(RELOAD_KEY, JSON.stringify({ direction: 'rtl', path: 'settings', atMillis: Date.now() }));
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, true, routing));
    await waitFor(() => expect(routing.reopen).toHaveBeenCalledWith('settings'));
    expect(await AsyncStorage.getItem(RELOAD_KEY)).toBeNull();
  });

  it('waits for the app to load before restoring a screen', async () => {
    rtl = true;
    await AsyncStorage.setItem(RELOAD_KEY, JSON.stringify({ direction: 'rtl', path: '/products', atMillis: Date.now() }));
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, false, routing));
    await settle();
    expect(routing.reopen).not.toHaveBeenCalled();
  });

  it('lets appLocale win for the launch when it names a shipped language', async () => {
    pick(UseSmileIDSampleLanguage.English);
    const { result } = await renderHook(() => useSmileIDSampleAppLanguage('fr-FR', false, routing));
    expect(result.current.language).toBe('fr');
  });
});

describe('the screen a reload returns to', () => {
  it('is products before the flow has started', async () => {
    showing = null;
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, true, routing));
    await waitFor(() => expect(reloadAppAsync).toHaveBeenCalledTimes(1));
    expect(JSON.parse((await AsyncStorage.getItem(RELOAD_KEY))!).path).toBe('products');
  });

  it('is not reopened when the replayed launch already shows it', async () => {
    rtl = true;
    await AsyncStorage.setItem(RELOAD_KEY, JSON.stringify({ direction: 'rtl', path: 'settings', atMillis: Date.now() }));
    pick(UseSmileIDSampleLanguage.Arabic);
    await renderHook(() => useSmileIDSampleAppLanguage(null, true, routing));
    await waitFor(async () => expect(await AsyncStorage.getItem(RELOAD_KEY)).toBeNull());
    expect(routing.reopen).not.toHaveBeenCalled();
  });
});

describe('System', () => {
  it('follows the device when its language changes while the app runs', async () => {
    const { result, rerender } = await renderHook(() => useSmileIDSampleAppLanguage(null, false, routing));
    expect(result.current.language).toBe('en');
    mockLocales = [{ languageTag: 'de-DE' }, { languageTag: 'fr-FR' }];
    await rerender({});
    expect(result.current.language).toBe('fr');
    mockLocales = [{ languageTag: 'en-US' }];
    await rerender({});
    expect(result.current.language).toBe('en');
    expect(result.current.deviceLanguages).toEqual(['en-US']);
  });
});

describe('the catalogue language', () => {
  it('asks in the pinned language, and in the device locale under System', async () => {
    pick(UseSmileIDSampleLanguage.French);
    const { rerender } = await renderHook(() => useSmileIDSampleAppLanguage(null, false, routing));
    await waitFor(() => expect(smileIDSampleCatalogueLocale()).toBe('fr'));

    pick(UseSmileIDSampleLanguage.System);
    await rerender({});
    await waitFor(() =>
      expect(smileIDSampleCatalogueLocale()).toBe('en-GB'),
    );
  });
});
