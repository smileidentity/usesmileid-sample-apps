import AsyncStorage from '@react-native-async-storage/async-storage';
import { UseSmileIDLocalizations } from '@smileid/usesmileid';
import {
  smileIDSampleLanguageIsRightToLeft,
  smileIDSampleResolvedLanguage,
  smileIDSampleShippedLanguage,
  useSmileIDSampleSettingsStore,
  UseSmileIDSampleLanguage,
} from '@smileid/sample-ui';
import { reloadAppAsync } from 'expo';
import { useLocales } from 'expo-localization';
import { type Href, usePathname, useRouter } from 'expo-router';
import { useEffect, useMemo, useRef } from 'react';
import { I18nManager } from 'react-native';

import ar from './l10n/ar.json';
import fr from './l10n/fr.json';
import he from './l10n/he.json';
import { smileIDSampleSetPinnedLanguage } from './use-smile-id-sample-pinned-language';

UseSmileIDLocalizations.register('fr', fr);
UseSmileIDLocalizations.register('ar', ar);
UseSmileIDLocalizations.register('he', he);

/// What the SDK reads at each flow's mount, so a flow opens in the language the app shows.
const shown: { language: Exclude<UseSmileIDSampleLanguage, 'system'> } = { language: 'en' };
UseSmileIDLocalizations.localeResolver = () => shown.language;

/// The pending direction reload, read back after the restart.
const RELOAD_KEY = 'usesmileid-sample.directionReload';

/// The sheet a pick is made on, which closes as the pick lands, so the reload returns to its owner.
const LANGUAGE_SHEET = '/settings/language';
const SETTINGS = '/settings';

/// A direction reload, and the route to return to after it.
type Reload = { readonly direction: 'ltr' | 'rtl'; readonly path: string; readonly atMillis: number };

/// Long enough to cover the reload a pick asks for, so a later launch gets one fresh attempt.
const RELOAD_WINDOW_MILLIS = 60_000;

const readReload = async (): Promise<Reload | null> => {
  try {
    return JSON.parse((await AsyncStorage.getItem(RELOAD_KEY)) ?? 'null') as Reload | null;
  } catch {
    return null;
  }
};

/// The language the app shows: the launch's `appLocale`, then the Language setting, then the device's.
export const useSmileIDSampleAppLanguage = (
  appLocale: string | null,
  ready: boolean,
): {
  language: Exclude<UseSmileIDSampleLanguage, 'system'>;
  deviceLanguages: readonly string[];
} => {
  const locales = useLocales();
  const deviceLanguages = useMemo(() => locales.map((locale) => locale.languageTag), [locales]);
  const setting = useSmileIDSampleSettingsStore((state) => state.settings.language);
  const loaded = useSmileIDSampleSettingsStore((state) => state.loaded);
  const router = useRouter();
  const pathname = usePathname();
  const path = useRef(pathname);
  const pinned =
    (appLocale === null ? null : smileIDSampleShippedLanguage(appLocale)) ??
    (setting === UseSmileIDSampleLanguage.System ? null : setting);
  const language = pinned ?? smileIDSampleResolvedLanguage(setting, deviceLanguages);

  useEffect(() => {
    shown.language = language;
    smileIDSampleSetPinnedLanguage(pinned);
  }, [language, pinned]);

  useEffect(() => {
    path.current = pathname;
  }, [pathname]);

  // RN fixes direction at start, and a reload replays the launch link, so the route is restored.
  useEffect(() => {
    if (!loaded || !ready) return;
    const direction = smileIDSampleLanguageIsRightToLeft(language) ? 'rtl' : 'ltr';
    void readReload().then(async (last) => {
      if (I18nManager.isRTL === (direction === 'rtl')) {
        if (last === null) return;
        await AsyncStorage.removeItem(RELOAD_KEY);
        if (last.direction === direction && last.path !== path.current) router.replace(last.path as Href);
        return;
      }
      // Once per window, so a build that cannot apply it never loops.
      if (last?.direction === direction && Date.now() - last.atMillis < RELOAD_WINDOW_MILLIS) return;
      I18nManager.allowRTL(direction === 'rtl');
      I18nManager.forceRTL(direction === 'rtl');
      await AsyncStorage.setItem(
        RELOAD_KEY,
        JSON.stringify({
          direction,
          path: path.current === LANGUAGE_SHEET ? SETTINGS : path.current,
          atMillis: Date.now(),
        } satisfies Reload),
      );
      await reloadAppAsync('layout direction changed');
    });
  }, [loaded, ready, language, router]);

  return { language, deviceLanguages };
};
