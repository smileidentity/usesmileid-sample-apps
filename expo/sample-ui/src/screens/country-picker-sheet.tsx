import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleCataloguePicker } from '../components/use-smile-id-sample-catalogue-picker';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import type { UseSmileIDSampleCatalogue } from '../state/use-smile-id-sample-catalogue';
import { smileIDSampleFlag, type UseSmileIDSampleCountry } from '../state/use-smile-id-sample-id-details';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>;
  selected: UseSmileIDSampleCountry | null;
  query: string;
  onQueryChange: (query: string) => void;
  onSelect: (country: UseSmileIDSampleCountry) => void;
  onRetry: () => void;
  onDismiss: () => void;
};

/// The country picker, filtering on the name, never the code; full height so the list does not fight the keyboard.
export const CountryPickerSheet = ({
  catalogue,
  selected,
  query,
  onQueryChange,
  onSelect,
  onRetry,
  onDismiss,
}: Props) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleBottomSheet
      visible
      fullHeight
      title={strings.pickerCountryTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.COUNTRY_SHEET}
    >
      <UseSmileIDSampleCataloguePicker
        catalogue={catalogue}
        loadingLabel={strings.pickerCountryLoading}
        failedLabel={strings.pickerCountryLoadFailed}
        query={query}
        onQueryChange={onQueryChange}
        searchPlaceholder={strings.pickerCountrySearch}
        searchTestID={UseSmileIDSampleTestIds.COUNTRY_SEARCH}
        label={(country) => country.name}
        emptyTestID={UseSmileIDSampleTestIds.COUNTRY_EMPTY}
        emptyLabel={(text) => strings.pickerCountryNoMatch({ query: text })}
        nothingToList={[strings.pickerCountryEmpty, strings.pickerCountryEmptyHint]}
        onRetry={onRetry}
        leadingCircle
        row={(country) => (
          <UseSmileIDSampleOptionRow
            key={country.code}
            label={country.name}
            selected={country.code === selected?.code}
            onPress={() => onSelect(country)}
            leadingText={smileIDSampleFlag(country.code)}
            testID={UseSmileIDSampleSuffixedTestIds.countryOption(country.code)}
          />
        )}
      />
    </UseSmileIDSampleBottomSheet>
  );
};
