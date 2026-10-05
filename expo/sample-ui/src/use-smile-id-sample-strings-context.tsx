import { createContext, type ReactNode, useContext, useMemo } from 'react';

import { smileIDSampleLanguageIsRightToLeft, type UseSmileIDSampleLanguage } from './model/use-smile-id-sample-language';
import { UseSmileIDSampleStrings } from './use-smile-id-sample-strings';

type Value = {
  readonly strings: UseSmileIDSampleStrings;
  readonly deviceLanguages: readonly string[];
  readonly rightToLeft: boolean;
  readonly language: Exclude<UseSmileIDSampleLanguage, 'system'>;
};

const english: Value = { strings: UseSmileIDSampleStrings.forLanguage('en'), deviceLanguages: [], rightToLeft: false, language: 'en' };

const Context = createContext<Value>(english);

type Props = {
  /// The language resolved for display, never System.
  language: Exclude<UseSmileIDSampleLanguage, 'system'>;
  /// The device's languages, which the System label resolves.
  deviceLanguages: readonly string[];
  children: ReactNode;
};

/// The language the app shows, for every component below; English outside one.
export const UseSmileIDSampleStringsProvider = ({ language, deviceLanguages, children }: Props) => {
  const value = useMemo(
    () => ({
      strings: UseSmileIDSampleStrings.forLanguage(language),
      deviceLanguages,
      rightToLeft: smileIDSampleLanguageIsRightToLeft(language),
      language,
    }),
    [language, deviceLanguages],
  );
  return <Context.Provider value={value}>{children}</Context.Provider>;
};

/// The copy in the language the app shows.
export const useSmileIDSampleStrings = (): UseSmileIDSampleStrings => useContext(Context).strings;

/// The device's languages, which the System label resolves.
export const useSmileIDSampleDeviceLanguages = (): readonly string[] => useContext(Context).deviceLanguages;

/// Whether the language shown reads right to left.
export const useSmileIDSampleRightToLeft = (): boolean => useContext(Context).rightToLeft;

/// The language the app shows, never System, for formatting dates and times in it.
export const useSmileIDSampleLanguageShown = (): Exclude<UseSmileIDSampleLanguage, 'system'> =>
  useContext(Context).language;
