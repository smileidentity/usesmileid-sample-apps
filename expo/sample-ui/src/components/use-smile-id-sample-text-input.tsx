import { useState, type ReactNode } from 'react';
import {
  StyleSheet,
  Text,
  TextInput,
  View,
  type KeyboardTypeOptions,
  type TextInputProps,
  type StyleProp,
  type TextStyle,
  type ViewStyle,
} from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's leading glyph box — 17, which no scale token carries.
const LEADING_SIZE = 17;

type Props = {
  value: string;
  onValueChange: (value: string) => void;
  placeholder?: string;
  enabled?: boolean;
  isError?: boolean;
  errorMessage?: string | null;
  keyboardType?: KeyboardTypeOptions;
  /// An ID number is entered uppercase, which is a keyboard hint rather than a transform.
  autoCapitalize?: TextInputProps['autoCapitalize'];
  masked?: boolean;
  textAlign?: TextStyle['textAlign'];
  testID?: string;
  leading?: (tint: string) => ReactNode;
  trailing?: (tint: string) => ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// A single-line field on the input tokens. Error outranks focus, so tapping back in does not hide the message.
export const UseSmileIDSampleTextInput = ({
  value,
  onValueChange,
  placeholder = '',
  enabled = true,
  isError = false,
  errorMessage,
  keyboardType,
  autoCapitalize,
  masked = false,
  textAlign,
  testID,
  leading,
  trailing,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const [focused, setFocused] = useState(false);
  const borderColor = isError
    ? theme.colors.input.borderError
    : focused
      ? theme.colors.input.borderFocus
      : theme.colors.input.border;

  return (
    <View style={style}>
      <View
        style={[
          styles.field,
          {
            minHeight: theme.dimens.size['control-md'],
            backgroundColor: enabled ? theme.colors.input.background : theme.colors.surfaceMuted,
            borderRadius: theme.dimens.radius.field,
            borderWidth:
              focused || isError ? theme.dimens.borderWidth.thin : theme.dimens.borderWidth.hairline,
            borderColor,
            paddingHorizontal: theme.dimens.spacing.md,
            paddingVertical: theme.dimens.spacing.sm,
            columnGap: theme.dimens.spacing.xs,
          },
        ]}
      >
        {leading ? (
          <View style={styles.leading}>{leading(theme.colors.input.placeholder)}</View>
        ) : null}
        <TextInput
          testID={testID}
          value={value}
          onChangeText={onValueChange}
          editable={enabled}
          placeholder={placeholder}
          placeholderTextColor={theme.colors.input.placeholder}
          secureTextEntry={masked}
          autoCorrect={!masked}
          autoCapitalize={autoCapitalize}
          keyboardType={keyboardType}
          selectionColor={theme.colors.input.borderFocus}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          // The field fills its column, so alignment set on the row would leave the text hard left.
          style={[
            theme.type.inputFont,
            styles.input,
            { color: enabled ? theme.colors.input.text : theme.colors.textMuted },
            textAlign ? { textAlign } : null,
          ]}
        />
        {trailing ? trailing(theme.colors.input.placeholder) : null}
      </View>
      {isError && errorMessage ? (
        <Text
          style={[
            theme.type.textStyleCaption,
            {
              color: theme.colors.input.borderError,
              marginStart: theme.dimens.spacing.md,
              marginTop: theme.dimens.space[4],
            },
          ]}
        >
          {errorMessage}
        </Text>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  field: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  leading: { alignItems: 'center', justifyContent: 'center', minHeight: LEADING_SIZE, minWidth: LEADING_SIZE },
  // Weighted so a trailing action keeps its width; with no trailing the field still fills.
  input: { flex: 1, padding: 0 },
});
