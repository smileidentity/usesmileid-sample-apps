import { Pressable, StyleSheet, View } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { smileBorderStrong } from '../smile-product-hues';
import { touchTargetStyle } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const CHECK_SIZE = 11;

type Props = {
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  testID?: string;
};

/// The select-mode checkbox. Circular rather than a rounded square, which is the design's correction.
export const UseSmileIDSampleSelectionCheckbox = ({ checked, onCheckedChange, testID }: Props) => {
  const theme = useSmileIDSampleTheme();
  const box = theme.dimens.size['icon-lg'];

  return (
    <Pressable
      testID={testID}
      accessibilityRole="checkbox"
      accessibilityState={{ checked }}
      onPress={() => onCheckedChange(!checked)}
      style={[styles.target, touchTargetStyle(theme)]}
    >
      <View
        style={[
          styles.box,
          {
            width: box,
            height: box,
            borderRadius: box / 2,
            // A 2px ring in border-strong: color.border is far too pale to read as a control.
            borderWidth: theme.dimens.borderWidth.thick,
            borderColor: checked ? theme.colors.primary : smileBorderStrong,
            backgroundColor: checked ? theme.colors.primary : theme.colors.surface,
          },
        ]}
      >
        {checked ? (
          <UseSmileIDSampleIcon name="check" tint={theme.colors.onPrimary} size={CHECK_SIZE} />
        ) : null}
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  target: { alignItems: 'center', justifyContent: 'center' },
  box: { alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
});
