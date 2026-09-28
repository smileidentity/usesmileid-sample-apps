import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleCataloguePicker } from '../components/use-smile-id-sample-catalogue-picker';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import type { UseSmileIDSampleCatalogue } from '../state/use-smile-id-sample-catalogue';
import { smileIDSampleFlag, type UseSmileIDSampleCountry } from '../state/use-smile-id-sample-id-details';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>;
  selected: UseSmileIDSampleCountry | null;
  query: string;
  onQueryChange: (query: string) => void;
  onSelect: (country: UseSmileIDSampleCountry) => void;
  onRetry: () => void;
  onDismiss: () => void;
};

/// The country picker, filtering on the name and never the code. Full height, because the list fights the keyboard otherwise.
export const CountryPickerSheet = ({
  catalogue,
  selected,
  query,
  onQueryChange,
  onSelect,
  onRetry,
  onDismiss,
}: Props) => (
  <UseSmileIDSampleBottomSheet
    visible
    fullHeight
    title="Country"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.COUNTRY_SHEET}
  >
    <UseSmileIDSampleCataloguePicker
      catalogue={catalogue}
      what="countries"
      query={query}
      onQueryChange={onQueryChange}
      searchPlaceholder="Search country"
      searchTestID={UseSmileIDSampleTestIds.COUNTRY_SEARCH}
      label={(country) => country.name}
      emptyTestID={UseSmileIDSampleTestIds.COUNTRY_EMPTY}
      emptyLabel={(text) => `No country matches “${text}”`}
      nothingToList={['No countries for this product', 'Try another product']}
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
