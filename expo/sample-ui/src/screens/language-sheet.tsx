import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import {
  smileIDSampleLanguageLabel,
  smileIDSampleLanguages,
  type UseSmileIDSampleLanguage,
} from '../model/use-smile-id-sample-language';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  selected: UseSmileIDSampleLanguage;
  /// The device's languages, which the System row resolves.
  deviceLanguages: readonly string[];
  onSelect: (language: UseSmileIDSampleLanguage) => void;
  onDismiss: () => void;
};

/// System, then each shipped language under its own name.
export const LanguageSheet = ({ selected, deviceLanguages, onSelect, onDismiss }: Props) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleBottomSheet
      visible
      title={strings.languageTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.LANGUAGE_SHEET}
    >
      {smileIDSampleLanguages.map((language) => (
        <UseSmileIDSampleOptionRow
          key={language}
          label={smileIDSampleLanguageLabel(language, strings, deviceLanguages)}
          selected={language === selected}
          onPress={() => onSelect(language)}
          testID={UseSmileIDSampleSuffixedTestIds.languageOption(language)}
        />
      ))}
    </UseSmileIDSampleBottomSheet>
  );
};
