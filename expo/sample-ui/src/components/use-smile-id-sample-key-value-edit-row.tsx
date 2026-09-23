import { StyleSheet, Text, TextInput, View, type KeyboardTypeOptions, type StyleProp, type ViewStyle } from 'react-native';

import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's own row metrics, which land between the scale steps — spec/components.json → KeyValueEditRow.
const ROW_TEXT_SIZE = 13.5;
const ROW_PADDING_X = 15;
const ROW_PADDING_Y = 14;

type Props = {
  label: string;
  value: string;
  onValueChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
  enabled?: boolean;
  keyboardType?: KeyboardTypeOptions;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// A label and a value that edits in place with a caret, rather than pushing a form.
export const UseSmileIDSampleKeyValueEditRow = ({
  label,
  value,
  onValueChange,
  placeholder = '',
  required = false,
  enabled = true,
  keyboardType,
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      style={[
        styles.row,
        {
          backgroundColor: theme.colors.surface,
          minHeight: theme.dimens.size['control-md'],
          paddingHorizontal: ROW_PADDING_X,
          paddingVertical: ROW_PADDING_Y,
          rowGap: theme.dimens.spacing.xxs,
        },
        style,
      ]}
    >
      <Text
        // The field name is title-coloured and only the placeholder is muted; Android had that inverted.
        style={[atSize(theme.type.textStyleSubtitle, ROW_TEXT_SIZE), { color: theme.colors.textTitle }]}
      >
        {required ? `${label} *` : label}
      </Text>
      <TextInput
        testID={testID}
        value={value}
        onChangeText={onValueChange}
        editable={enabled}
        placeholder={placeholder}
        placeholderTextColor={theme.colors.textMuted}
        keyboardType={keyboardType}
        selectionColor={theme.colors.primary}
        // A Compose text field trims only the top of its line, so the bottom half-leading stays.
        style={[
          atSize(theme.type.textStyleSubtitle, ROW_TEXT_SIZE),
          styles.keepBottomLeading,
          styles.field,
          { color: enabled ? theme.colors.textTitle : theme.colors.textMuted },
        ]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  // Wrapping so the value drops below the label at 2x, the same way the data-field row does.
  row: { alignItems: 'center', flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', width: '100%' },
  field: { padding: 0, textAlign: 'right' },
  keepBottomLeading: { marginBottom: 0 },
});
