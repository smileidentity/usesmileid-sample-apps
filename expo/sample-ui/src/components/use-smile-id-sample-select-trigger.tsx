import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { insetForBorder } from '../theme/smile-compose-layout';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const TRIGGER_TEXT_SIZE = 15;
const TRIGGER_EMOJI_SIZE = 18;
const CHEVRON_SIZE = 12;

/// The design leads each trigger with an emoji rather than a glyph, so it carries no tint.
export const UseSmileIDSampleTriggerEmoji = ({ emoji }: { emoji: string }) => {
  const theme = useSmileIDSampleTheme();
  return <Text style={atSize(theme.type.inputFont, TRIGGER_EMOJI_SIZE)}>{emoji}</Text>;
};

type Props = {
  value: string | null;
  placeholder: string;
  onPress: () => void;
  enabled?: boolean;
  testID?: string;
  leading?: (tint: string) => ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// Looks like an input, behaves like a button. Disabled is load-bearing: ID type stays greyed until a country is chosen.
export const UseSmileIDSampleSelectTrigger = ({
  value,
  placeholder,
  onPress,
  enabled = true,
  testID,
  leading,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  // The disabled pair, not textMuted on an almost-white surface, which does not read as disabled.
  const contentColor = !enabled
    ? theme.colors.button.disabledText
    : value !== null
      ? theme.colors.textTitle
      : theme.colors.input.placeholder;

  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityState={{ disabled: !enabled }}
      disabled={!enabled}
      onPress={onPress}
      style={[
        styles.trigger,
        {
          borderRadius: theme.dimens.radius.field,
          backgroundColor: enabled ? theme.colors.input.background : theme.colors.button.disabledBackground,
          borderWidth: theme.dimens.borderWidth.thin,
          borderColor: enabled ? theme.colors.primary : theme.colors.input.border,
          minHeight: theme.dimens.size['control-md'],
          paddingHorizontal: insetForBorder(theme.dimens.spacing.md, theme.dimens.borderWidth.thin),
          paddingVertical: insetForBorder(theme.dimens.spacing.sm, theme.dimens.borderWidth.thin),
          columnGap: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      {leading ? (
        // A minimum, not a fixed size: the leading slot may hold an emoji, which grows with font scale.
        <View
          style={[
            styles.leading,
            { minWidth: theme.dimens.size['icon-md'], minHeight: theme.dimens.size['icon-md'] },
          ]}
        >
          {leading(contentColor)}
        </View>
      ) : null}
      <Text
        style={[
          atSize(atWeight(theme.type.inputFont, 600), TRIGGER_TEXT_SIZE),
          styles.label,
          { color: contentColor },
        ]}
      >
        {value ?? placeholder}
      </Text>
      <UseSmileIDSampleIcon name="chevronDown" tint={contentColor} size={CHEVRON_SIZE} />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  trigger: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  leading: { alignItems: 'center', justifyContent: 'center' },
  label: { flex: 1 },
});
