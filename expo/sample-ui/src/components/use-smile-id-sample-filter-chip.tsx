import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth, smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const CHIP_LABEL_SIZE = 12.5;

type Props = {
  label: string;
  count: number;
  selected: boolean;
  onPress: () => void;
  testID?: string;
  countTestID?: string;
  style?: StyleProp<ViewStyle>;
};

/// A status filter with its live count. The count is a separate node, because it is what a delete is asserted on.
export const UseSmileIDSampleFilterChip = ({
  label,
  count,
  selected,
  onPress,
  testID,
  countTestID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <Pressable
      testID={testID}
      accessibilityRole="tab"
      accessibilityState={{ selected }}
      onPress={onPress}
      // Laid out at the platform's touch target with the chip centred in it, as Compose's minimum size does.
      style={[styles.target, { minHeight: theme.dimens.touchTarget }, style]}
    >
      <View
        style={[
          styles.chip,
          {
            borderRadius: theme.dimens.radius.chip,
            backgroundColor: selected ? theme.colors.primary : theme.colors.filterChip.background,
            borderWidth: selected ? 0 : smileCardStrokeWidth,
            borderColor: selected ? 'transparent' : theme.colors.cardStroke,
            minHeight: theme.dimens.space[32],
            // Compose draws the stroke over the padding; here it sits inside the box, so it comes off the padding.
            paddingHorizontal: theme.dimens.spacing.sm - (selected ? 0 : smileCardStrokeWidth),
            paddingVertical: theme.dimens.spacing.xs - (selected ? 0 : smileCardStrokeWidth),
            columnGap: theme.dimens.spacing.xxs,
          },
        ]}
      >
        <Text
          style={[
            atSize(atWeight(theme.type.filterChipFont, 700), CHIP_LABEL_SIZE),
            { color: selected ? theme.colors.onPrimary : theme.colors.filterChip.label },
          ]}
        >
          {label}
        </Text>
        <Text
          testID={countTestID}
          // The design file's muted grey, deliberately not filter.chip-value's blue.
          style={[
            atSize(theme.type.textStyleOverline, smileLabelSize),
            {
              letterSpacing: smileLabelTracking,
              color: selected ? theme.colors.onPrimary : theme.colors.textMuted,
            },
          ]}
        >
          {count}
        </Text>
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  target: { alignSelf: 'flex-start', justifyContent: 'center' },
  chip: { alignItems: 'center', flexDirection: 'row' },
});
