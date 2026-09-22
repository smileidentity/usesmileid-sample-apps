import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { smileCardStrokeWidth } from '../smile-product-hues';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's tile is 38 at radius 11 and the chevron 14, none of which the scale carries.
const TILE_SIZE = 38;
const TILE_RADIUS = 11;
const CHEVRON_SIZE = 14;

type Props = {
  title: string;
  supportingText?: string;
  testID?: string;
  onPress?: () => void;
  leading?: (tint: string) => ReactNode;
  trailing?: ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// A settings row: a glyph tile, a title with an optional supporting line, and a trailing control.
export const UseSmileIDSampleSettingRow = ({
  title,
  supportingText,
  testID,
  onPress,
  leading,
  trailing,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const Row = onPress ? Pressable : View;

  return (
    <Row
      testID={testID}
      {...(onPress ? { accessibilityRole: 'button' as const, onPress } : {})}
      style={[
        styles.row,
        {
          minHeight: theme.dimens.space[64],
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.spacing.sm,
          columnGap: theme.dimens.spacing.sm,
        },
        style,
      ]}
    >
      {leading ? (
        <View
          style={[
            styles.tile,
            // surface-2, a cool grey — surface-alt is a warm cream and shipped peach tiles once.
            { width: TILE_SIZE, height: TILE_SIZE, borderRadius: TILE_RADIUS, backgroundColor: theme.colors.surfaceTile },
          ]}
        >
          {leading(theme.colors.textTitle)}
        </View>
      ) : null}
      <View style={[styles.text, { rowGap: theme.dimens.spacing.xxs }]}>
        <Text style={[theme.type.textStyleBodyStrong, { color: theme.colors.textTitle }]}>{title}</Text>
        {supportingText !== undefined ? (
          <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>
            {supportingText}
          </Text>
        ) : null}
      </View>
      {trailing}
    </Row>
  );
};

/// The trailing chevron that says the row pushes a screen.
export const UseSmileIDSampleSettingRowChevron = () => {
  const theme = useSmileIDSampleTheme();
  return <UseSmileIDSampleIcon name="chevron" tint={theme.colors.textMuted} size={CHEVRON_SIZE} />;
};

/// Sign out: full width, centred, and in the soft error text rather than the saturated fill.
export const UseSmileIDSampleDestructiveRow = ({
  text,
  onPress,
  testID,
  style,
}: {
  text: string;
  onPress: () => void;
  testID?: string;
  style?: StyleProp<ViewStyle>;
}) => {
  const theme = useSmileIDSampleTheme();
  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      onPress={onPress}
      // Laid out at the platform's touch target with the row centred in it, as Compose's minimum size does.
      style={[styles.target, { minHeight: theme.dimens.touchTarget }, style]}
    >
      <View
        style={[
          styles.destructive,
          {
            minHeight: theme.dimens.size['control-md'],
            // Compose draws the stroke over the padding; here it sits inside the box, so it comes off the padding.
            padding: theme.dimens.spacing.sm - smileCardStrokeWidth,
            borderRadius: theme.shapes.card,
            backgroundColor: theme.colors.surface,
            borderWidth: smileCardStrokeWidth,
            borderColor: theme.colors.cardStroke,
          },
        ]}
      >
        <Text
          style={[theme.type.textStyleButton, styles.centred, { color: theme.colors.badge.errorText }]}
        >
          {text}
        </Text>
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  tile: { alignItems: 'center', justifyContent: 'center' },
  text: { flex: 1 },
  target: { alignSelf: 'stretch', justifyContent: 'center' },
  destructive: { alignItems: 'center', justifyContent: 'center' },
  centred: { textAlign: 'center' },
});
