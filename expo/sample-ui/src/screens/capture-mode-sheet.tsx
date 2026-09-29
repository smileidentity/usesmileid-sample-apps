import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { smileIDSampleCaptureModes, type UseSmileIDSampleCaptureMode } from '../model/use-smile-id-sample-capture-mode';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  selected: UseSmileIDSampleCaptureMode;
  onSelect: (mode: UseSmileIDSampleCaptureMode) => void;
  onDismiss: () => void;
};

/// DocumentCaptureConfig.captureMode's three values; the fallback keeps the SDK's 10 seconds.
export const CaptureModeSheet = ({ selected, onSelect, onDismiss }: Props) => (
  <UseSmileIDSampleBottomSheet
    visible
    title="Capture mode"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.CAPTURE_MODE_SHEET}
  >
    {smileIDSampleCaptureModes.map((mode) => (
      <UseSmileIDSampleOptionRow
        key={mode.id}
        label={mode.label}
        selected={mode.id === selected}
        onPress={() => onSelect(mode.id)}
        testID={UseSmileIDSampleSuffixedTestIds.captureModeOption(mode.id)}
      />
    ))}
  </UseSmileIDSampleBottomSheet>
);
