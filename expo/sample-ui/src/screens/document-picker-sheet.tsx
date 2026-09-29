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
}: Props) => (
  <UseSmileIDSampleBottomSheet
    visible
    fullHeight
    title="Document"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.DOCUMENT_SHEET}
  >
    <UseSmileIDSampleCataloguePicker
      catalogue={catalogue}
      what="documents"
      query={query}
      onQueryChange={onQueryChange}
      searchPlaceholder="Search document"
      searchTestID={UseSmileIDSampleTestIds.DOCUMENT_SEARCH}
      label={(document) => document.name}
      emptyTestID={UseSmileIDSampleTestIds.DOCUMENT_EMPTY}
      emptyLabel={(text) => `No document matches “${text}”`}
      nothingToList={[`No documents for ${country?.name ?? 'this country'}`, 'Choose another country']}
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
