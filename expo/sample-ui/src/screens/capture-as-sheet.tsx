import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { smileIDSampleCaptureAsOptions, type UseSmileIDSampleCaptureAs } from '../model/use-smile-id-sample-capture-as';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  selected: UseSmileIDSampleCaptureAs;
  onSelect: (captureAs: UseSmileIDSampleCaptureAs) => void;
  onDismiss: () => void;
};

/// How the SDK photographs the document; choosing Custom hands over to the custom-document sheet.
export const CaptureAsSheet = ({ selected, onSelect, onDismiss }: Props) => (
  <UseSmileIDSampleBottomSheet
    visible
    title="Capture as"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.CAPTURE_AS_SHEET}
  >
    {smileIDSampleCaptureAsOptions.map((option) => (
      <UseSmileIDSampleOptionRow
        key={option.id}
        label={option.label}
        selected={option.id === selected}
        onPress={() => onSelect(option.id)}
        testID={UseSmileIDSampleSuffixedTestIds.captureAsOption(option.id)}
      />
    ))}
  </UseSmileIDSampleBottomSheet>
);
