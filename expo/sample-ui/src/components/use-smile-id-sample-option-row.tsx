import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const FLAG_SIZE = 19;
const OPTION_LABEL_SIZE = 14;

type Props = {
  label: string;
  selected: boolean;
  onPress: () => void;
  leadingText?: string;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// One row in the country or ID-type picker; country rows lead with a flag, and selected takes a pale fill as well as a check.
export const UseSmileIDSampleOptionRow = ({
  label,
  selected,
  onPress,
  leadingText,
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <Pressable
      testID={testID}
      accessibilityRole="radio"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[
        styles.row,
        {
          borderRadius: theme.dimens.radius.field,
          // An unselected row is transparent over the sheet; only the selected one takes a fill.
          backgroundColor: selected ? theme.colors.surfaceTile : 'transparent',
          minHeight: theme.dimens.size['control-md'],
          paddingHorizontal: theme.dimens.spacing.sm,
          paddingVertical: theme.dimens.spacing.xs,
          columnGap: theme.dimens.spacing.sm,
        },
        style,
      ]}
    >
      {leadingText !== undefined ? (
        <Text style={atSize(theme.type.textStyleBody, FLAG_SIZE)}>{leadingText}</Text>
      ) : null}
      <Text
        style={[
          atSize(theme.type.textStyleBodyStrong, OPTION_LABEL_SIZE),
          styles.label,
          { color: theme.colors.textTitle },
        ]}
      >
        {label}
      </Text>
      {selected ? (
        <View style={[styles.check, { width: theme.dimens.size['icon-md'], height: theme.dimens.size['icon-md'] }]}>
          <UseSmileIDSampleIcon name="check" tint={theme.colors.primary} />
        </View>
      ) : null}
    </Pressable>
  );
};

const styles = StyleSheet.create({
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  label: { flex: 1 },
  check: { alignItems: 'center', justifyContent: 'center' },
});
