import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import {
  smileIDSampleAppearanceLabel,
  smileIDSampleAppearances,
  type UseSmileIDSampleAppearance,
} from '../model/use-smile-id-sample-appearance';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  selected: UseSmileIDSampleAppearance;
  /// The device's own theme, never the one the app renders.
  deviceDark: boolean;
  onSelect: (appearance: UseSmileIDSampleAppearance) => void;
  onDismiss: () => void;
};

/// The three appearances; System's label names `deviceDark`, the device's own theme.
export const AppearanceSheet = ({ selected, deviceDark, onSelect, onDismiss }: Props) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleBottomSheet
      visible
      title={strings.appearanceTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.APPEARANCE_SHEET}
    >
      {smileIDSampleAppearances.map((appearance) => (
        <UseSmileIDSampleOptionRow
          key={appearance}
          label={smileIDSampleAppearanceLabel(appearance, deviceDark, strings)}
          selected={appearance === selected}
          onPress={() => onSelect(appearance)}
          testID={UseSmileIDSampleSuffixedTestIds.appearanceOption(appearance)}
        />
      ))}
    </UseSmileIDSampleBottomSheet>
  );
};
