import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { UseSmileIDSamplePickerList } from '../components/use-smile-id-sample-picker-list';
import { UseSmileIDSampleSearchField } from '../components/use-smile-id-sample-search-field';
import {
  smileIDSampleCountries,
  smileIDSampleOptionMatches,
  type UseSmileIDSampleCountry,
} from '../state/use-smile-id-sample-id-details';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';

type Props = {
  selected: UseSmileIDSampleCountry | null;
  query: string;
  onQueryChange: (query: string) => void;
  onSelect: (country: UseSmileIDSampleCountry) => void;
  onDismiss: () => void;
};

/// The country picker. Full height, because the list is long enough that a partial sheet fights the keyboard.
export const CountryPickerSheet = ({
  selected,
  query,
  onQueryChange,
  onSelect,
  onDismiss,
}: Props) => {
  const matches = smileIDSampleCountries.filter((country) =>
    smileIDSampleOptionMatches(country.label, query),
  );

  return (
    <UseSmileIDSampleBottomSheet
      visible
      fullHeight
      title="Country"
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.COUNTRY_SHEET}
    >
      <UseSmileIDSampleSearchField
        query={query}
        onQueryChange={onQueryChange}
        placeholder="Search country"
        testID={UseSmileIDSampleTestIds.COUNTRY_SEARCH}
      />
      <UseSmileIDSamplePickerList
        empty={matches.length === 0}
        emptyLabel={`No country matches “${query}”`}
        emptyTestID={UseSmileIDSampleTestIds.COUNTRY_EMPTY}
      >
        {matches.map((country) => (
          <UseSmileIDSampleOptionRow
            key={country.code}
            label={country.label}
            selected={country.code === selected?.code}
            onPress={() => onSelect(country)}
            leadingText={country.flag}
            testID={UseSmileIDSampleSuffixedTestIds.countryOption(country.code)}
          />
        ))}
      </UseSmileIDSamplePickerList>
    </UseSmileIDSampleBottomSheet>
  );
};
