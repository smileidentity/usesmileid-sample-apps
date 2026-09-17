import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { UseSmileIDSamplePickerList } from '../components/use-smile-id-sample-picker-list';
import { UseSmileIDSampleSearchField } from '../components/use-smile-id-sample-search-field';
import {
  smileIDSampleIdTypesFor,
  smileIDSampleOptionMatches,
  type UseSmileIDSampleCountry,
  type UseSmileIDSampleIdType,
} from '../state/use-smile-id-sample-id-details';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';

type Props = {
  country: UseSmileIDSampleCountry | null;
  selected: UseSmileIDSampleIdType | null;
  query: string;
  onQueryChange: (query: string) => void;
  onSelect: (idType: UseSmileIDSampleIdType) => void;
  onDismiss: () => void;
};

/// The ID-type picker. Its list depends on the country, which is why the trigger opening it is disabled without one.
export const IdTypePickerSheet = ({
  country,
  selected,
  query,
  onQueryChange,
  onSelect,
  onDismiss,
}: Props) => {
  const matches = smileIDSampleIdTypesFor(country).filter((idType) =>
    smileIDSampleOptionMatches(idType.label, query),
  );

  return (
    <UseSmileIDSampleBottomSheet
      visible
      fullHeight
      title="ID type"
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.ID_TYPE_SHEET}
    >
      <UseSmileIDSampleSearchField
        query={query}
        onQueryChange={onQueryChange}
        placeholder="Search ID type"
        testID={UseSmileIDSampleTestIds.ID_TYPE_SEARCH}
      />
      <UseSmileIDSamplePickerList
        empty={matches.length === 0}
        emptyLabel={
          query.trim().length === 0
            ? 'No ID type for this country'
            : `No ID type matches “${query}”`
        }
        emptyTestID={UseSmileIDSampleTestIds.ID_TYPE_EMPTY}
      >
        {matches.map((idType) => (
          <UseSmileIDSampleOptionRow
            key={idType.id}
            label={idType.label}
            selected={idType.id === selected?.id}
            onPress={() => onSelect(idType)}
            testID={UseSmileIDSampleSuffixedTestIds.idTypeOption(idType.id)}
          />
        ))}
      </UseSmileIDSamplePickerList>
    </UseSmileIDSampleBottomSheet>
  );
};
