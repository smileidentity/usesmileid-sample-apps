import { Pressable, StyleSheet, Text, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth, smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atWeight } from '../theme/smile-type';
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
      // The design draws 34 tall; the platform minimum is reached with slop rather than a taller chip.
      hitSlop={7}
      style={[
        styles.chip,
        {
          borderRadius: theme.dimens.radius.chip,
          backgroundColor: selected ? theme.colors.primary : theme.colors.filterChip.background,
          borderWidth: selected ? 0 : smileCardStrokeWidth,
          borderColor: selected ? 'transparent' : theme.colors.cardStroke,
          minHeight: theme.dimens.space[32],
          paddingHorizontal: theme.dimens.spacing.sm,
          paddingVertical: theme.dimens.spacing.xs,
          columnGap: theme.dimens.spacing.xxs,
        },
        style,
      ]}
    >
      <Text
        style={[
          atWeight(theme.type.filterChipFont, 700),
          { fontSize: CHIP_LABEL_SIZE, color: selected ? theme.colors.onPrimary : theme.colors.filterChip.label },
        ]}
      >
        {label}
      </Text>
      <Text
        testID={countTestID}
        // The design file's muted grey, deliberately not filter.chip-value's blue.
        style={[
          theme.type.textStyleOverline,
          {
            fontSize: smileLabelSize,
            letterSpacing: smileLabelTracking,
            color: selected ? theme.colors.onPrimary : theme.colors.textMuted,
          },
        ]}
      >
        {count}
      </Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  chip: { alignItems: 'center', alignSelf: 'flex-start', flexDirection: 'row' },
});
