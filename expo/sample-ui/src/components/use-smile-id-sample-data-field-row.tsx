import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const FIELD_TEXT_SIZE = 13;

type Props = {
  label: string;
  value: string;
  testID?: string;
  onCopy?: () => void;
  copyTestID?: string;
  /// Set only where the design colours the value, as the Status row's HTTP code is.
  valueColor?: string;
  style?: StyleProp<ViewStyle>;
};

/// A label/value pair on the verification-details card, optionally with a copy control.
export const UseSmileIDSampleDataFieldRow = ({
  label,
  value,
  testID,
  onCopy,
  copyTestID,
  valueColor,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      testID={testID}
      style={[
        styles.row,
        {
          minHeight: theme.dimens.space[40],
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.spacing.sm,
          columnGap: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      <Text
        style={[
          theme.type.dataFieldLabelFont,
          { fontSize: FIELD_TEXT_SIZE, color: theme.colors.dataField.label },
        ]}
      >
        {label}
      </Text>
      {/* A column of its own, wrapping inside it: a wrapping row sent long values below the label. */}
      <Text
        style={[
          atWeight(theme.type.dataFieldValueFont, valueColor === undefined ? 600 : 700),
          styles.value,
          { fontSize: FIELD_TEXT_SIZE, color: valueColor ?? theme.colors.dataField.value },
        ]}
      >
        {value}
      </Text>
      {onCopy ? <CopyButton label={label} onCopy={onCopy} testID={copyTestID} /> : null}
    </View>
  );
};

const CopyButton = ({
  label,
  onCopy,
  testID,
}: {
  label: string;
  onCopy: () => void;
  testID?: string;
}) => {
  const theme = useSmileIDSampleTheme();
  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityLabel={`Copy ${label}`}
      onPress={onCopy}
      // The glyph is 24; the platform minimum is reached with slop rather than by growing the row.
      hitSlop={12}
      style={[
        styles.copy,
        {
          width: theme.dimens.size['icon-lg'],
          height: theme.dimens.size['icon-lg'],
          borderRadius: theme.dimens.radius.sm,
          backgroundColor: theme.colors.surfaceTile,
        },
      ]}
    >
      <UseSmileIDSampleIcon name="copy" tint={theme.colors.textMuted} size={theme.dimens.size['icon-sm']} />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  value: { flex: 1, textAlign: 'right' },
  copy: { alignItems: 'center', justifyContent: 'center' },
});
