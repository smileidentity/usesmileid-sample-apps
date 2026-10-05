import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import {
  smileIDSampleCaptureAsOptions,
  smileIDSampleMatchDocumentId,
  type UseSmileIDSampleCaptureAs,
} from '../model/use-smile-id-sample-capture-as';
import { smileIDSampleMatchRowLabel, type UseSmileIDSampleResolvedCaptureAs } from '../state/use-smile-id-sample-id-details';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  /// Null is Match document.
  selected: UseSmileIDSampleCaptureAs | null;
  /// What Match document resolves to for the chosen row, which its row names.
  matched: UseSmileIDSampleResolvedCaptureAs;
  onSelect: (captureAs: UseSmileIDSampleCaptureAs | null) => void;
  onDismiss: () => void;
};

/// How the SDK photographs the document: Match document first, then the overrides; Generic document hands over to its sheet.
export const CaptureAsSheet = ({ selected, matched, onSelect, onDismiss }: Props) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleBottomSheet
      visible
      title={strings.captureAsTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.CAPTURE_AS_SHEET}
    >
      <UseSmileIDSampleOptionRow
        label={smileIDSampleMatchRowLabel(matched, strings)}
        selected={selected === null}
        onPress={() => onSelect(null)}
        testID={UseSmileIDSampleSuffixedTestIds.captureAsOption(smileIDSampleMatchDocumentId)}
      />
      {smileIDSampleCaptureAsOptions.map((option) => (
        <UseSmileIDSampleOptionRow
          key={option.id}
          label={option.label(strings)}
          selected={option.id === selected}
          onPress={() => onSelect(option.id)}
          testID={UseSmileIDSampleSuffixedTestIds.captureAsOption(option.id)}
        />
      ))}
    </UseSmileIDSampleBottomSheet>
  );
};
