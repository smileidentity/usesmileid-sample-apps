let pinned: string | null = null;

/// The language the app is pinned to, by `appLocale` or the Language setting; null follows the device.
export const smileIDSamplePinnedLanguage = (): string | null => pinned;

/// Written only by the root layout's language hook, as the language resolves.
export const smileIDSampleSetPinnedLanguage = (language: string | null): void => {
  pinned = language;
};
