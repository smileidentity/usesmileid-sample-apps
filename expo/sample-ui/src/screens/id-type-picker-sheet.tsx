import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleCataloguePicker } from '../components/use-smile-id-sample-catalogue-picker';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import type { UseSmileIDSampleCatalogue } from '../state/use-smile-id-sample-catalogue';
import type { UseSmileIDSampleCountry, UseSmileIDSampleKycIdType } from '../state/use-smile-id-sample-id-details';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  country: UseSmileIDSampleCountry | null;
  catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType>;
  selected: UseSmileIDSampleKycIdType | null;
  query: string;
  onQueryChange: (query: string) => void;
  onSelect: (idType: UseSmileIDSampleKycIdType) => void;
  onRetry: () => void;
  onDismiss: () => void;
};

/// The ID-type picker, from the types the chosen country offers.
export const IdTypePickerSheet = ({
  country,
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
    title="ID type"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.ID_TYPE_SHEET}
  >
    <UseSmileIDSampleCataloguePicker
      catalogue={catalogue}
      what="ID types"
      query={query}
      onQueryChange={onQueryChange}
      searchPlaceholder="Search ID type"
      searchTestID={UseSmileIDSampleTestIds.ID_TYPE_SEARCH}
      label={(idType) => idType.label}
      emptyTestID={UseSmileIDSampleTestIds.ID_TYPE_EMPTY}
      emptyLabel={(text) => `No ID type matches “${text}”`}
      nothingToList={[`No ID types for ${country?.name ?? 'this country'}`, 'Choose another country']}
      onRetry={onRetry}
      row={(idType) => (
        <UseSmileIDSampleOptionRow
          key={idType.id}
          label={idType.label}
          selected={idType.id === selected?.id}
          onPress={() => onSelect(idType)}
          testID={UseSmileIDSampleSuffixedTestIds.idTypeOption(idType.id)}
        />
      )}
    />
  </UseSmileIDSampleBottomSheet>
);
