import {
  smileIDSampleLanguageIsRightToLeft,
  smileIDSampleLanguageLabel,
  smileIDSampleLanguages,
  smileIDSampleResolvedLanguage,
  smileIDSampleShippedLanguage,
  UseSmileIDSampleLanguage,
} from '../src/model/use-smile-id-sample-language';
import { smileIDSampleSettingsDefaults } from '../src/state/use-smile-id-sample-settings';
import { UseSmileIDSampleStrings } from '../src/use-smile-id-sample-strings';
import { spec } from './spec-file';

const strings = UseSmileIDSampleStrings.forLanguage('en');

describe('the language setting', () => {
  it('defaults to System', () => {
    expect(smileIDSampleSettingsDefaults.language).toBe(UseSmileIDSampleLanguage.System);
  });

  it('offers System, then every language spec/l10n/languages.json ships, in its order', () => {
    const shipped = spec<{ languages: { id: string }[] }>('l10n/languages.json').languages.map((it) => it.id);
    expect(smileIDSampleLanguages).toEqual(['system', ...shipped]);
  });

  it('resolves System to the first device language the app ships, else English', () => {
    expect(smileIDSampleResolvedLanguage(UseSmileIDSampleLanguage.System, ['de-DE', 'fr-CA'])).toBe('fr');
    expect(smileIDSampleResolvedLanguage(UseSmileIDSampleLanguage.System, ['de-DE'])).toBe('en');
    expect(smileIDSampleResolvedLanguage(UseSmileIDSampleLanguage.Arabic, ['fr-FR'])).toBe('ar');
  });

  it("reads Android's legacy Hebrew tag as Hebrew", () => {
    expect(smileIDSampleShippedLanguage('iw-IL')).toBe('he');
  });

  it('names the resolved language under System, and each language in itself', () => {
    expect(smileIDSampleLanguageLabel(UseSmileIDSampleLanguage.System, strings, ['fr-FR'])).toBe('System (Français)');
    expect(smileIDSampleLanguageLabel(UseSmileIDSampleLanguage.Hebrew, strings, [])).toBe('עברית');
  });

  it('lays Arabic and Hebrew out right to left', () => {
    expect(smileIDSampleLanguages.filter(smileIDSampleLanguageIsRightToLeft)).toEqual(['ar', 'he']);
  });
});
