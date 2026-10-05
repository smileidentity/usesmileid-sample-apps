import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleCataloguePicker } from '../components/use-smile-id-sample-catalogue-picker';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import type { UseSmileIDSampleCatalogue } from '../state/use-smile-id-sample-catalogue';
import {
  smileIDSampleDocumentId,
  type UseSmileIDSampleCountry,
  type UseSmileIDSampleDocument,
} from '../state/use-smile-id-sample-id-details';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  country: UseSmileIDSampleCountry | null;
  catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleDocument>;
  selected: UseSmileIDSampleDocument | null;
  query: string;
  onQueryChange: (query: string) => void;
  onSelect: (document: UseSmileIDSampleDocument) => void;
  onRetry: () => void;
  onDismiss: () => void;
};

/// The document products' picker: the country's supported documents, a standalone sub-type as its own row.
export const DocumentPickerSheet = ({
  country,
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
      title={strings.pickerDocumentTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.DOCUMENT_SHEET}
    >
      <UseSmileIDSampleCataloguePicker
        catalogue={catalogue}
        loadingLabel={strings.pickerDocumentLoading}
        failedLabel={strings.pickerDocumentLoadFailed}
        query={query}
        onQueryChange={onQueryChange}
        searchPlaceholder={strings.pickerDocumentSearch}
        searchTestID={UseSmileIDSampleTestIds.DOCUMENT_SEARCH}
        label={(document) => document.name}
        emptyTestID={UseSmileIDSampleTestIds.DOCUMENT_EMPTY}
        emptyLabel={(text) => strings.pickerDocumentNoMatch({ query: text })}
        nothingToList={[strings.pickerDocumentEmpty({ country: country?.name ?? strings.pickerThisCountry }), strings.pickerChooseAnotherCountry]}
        onRetry={onRetry}
        row={(document) => (
          <UseSmileIDSampleOptionRow
            key={smileIDSampleDocumentId(document)}
            label={document.name}
            selected={selected !== null && smileIDSampleDocumentId(document) === smileIDSampleDocumentId(selected)}
            onPress={() => onSelect(document)}
            testID={UseSmileIDSampleSuffixedTestIds.documentOption(smileIDSampleDocumentId(document))}
          />
        )}
      />
    </UseSmileIDSampleBottomSheet>
  );
};
