import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// The app's language: System follows the device; the rest are in `spec/l10n/languages.json`.
export const UseSmileIDSampleLanguage = {
  System: 'system',
  English: 'en',
  French: 'fr',
  Arabic: 'ar',
  Hebrew: 'he',
} as const;

export type UseSmileIDSampleLanguage = (typeof UseSmileIDSampleLanguage)[keyof typeof UseSmileIDSampleLanguage];

/// The sheet's rows in order.
export const smileIDSampleLanguages: readonly UseSmileIDSampleLanguage[] = [
  UseSmileIDSampleLanguage.System,
  UseSmileIDSampleLanguage.English,
  UseSmileIDSampleLanguage.French,
  UseSmileIDSampleLanguage.Arabic,
  UseSmileIDSampleLanguage.Hebrew,
];

/// Each language's name in itself, which no other language translates.
const endonyms: Record<Exclude<UseSmileIDSampleLanguage, 'system'>, string> = {
  en: 'English',
  fr: 'Français',
  ar: 'العربية',
  he: 'עברית',
};

/// The shipped language a BCP 47 tag names, by its language subtag; Android still reports Hebrew as `iw`.
export const smileIDSampleShippedLanguage = (tag: string): Exclude<UseSmileIDSampleLanguage, 'system'> | null => {
  const subtag = tag.split(/[-_]/)[0]?.toLowerCase() ?? '';
  const id = subtag === 'iw' ? 'he' : subtag;
  return id in endonyms ? (id as Exclude<UseSmileIDSampleLanguage, 'system'>) : null;
};

/// System resolves to the first device language the app ships, else English.
export const smileIDSampleResolvedLanguage = (
  language: UseSmileIDSampleLanguage,
  deviceLanguages: readonly string[],
): Exclude<UseSmileIDSampleLanguage, 'system'> =>
  language !== UseSmileIDSampleLanguage.System
    ? language
    : (deviceLanguages.map(smileIDSampleShippedLanguage).find((it) => it !== null) ?? 'en');

/// Whether the language reads right to left.
export const smileIDSampleLanguageIsRightToLeft = (language: UseSmileIDSampleLanguage): boolean =>
  language === UseSmileIDSampleLanguage.Arabic || language === UseSmileIDSampleLanguage.Hebrew;

/// System names the language the device resolves to; a named language is its own endonym.
export const smileIDSampleLanguageLabel = (
  language: UseSmileIDSampleLanguage,
  strings: UseSmileIDSampleStrings,
  deviceLanguages: readonly string[],
): string =>
  language === UseSmileIDSampleLanguage.System
    ? strings.languageSystem({ language: endonyms[smileIDSampleResolvedLanguage(language, deviceLanguages)] })
    : endonyms[language];
