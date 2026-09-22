import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleAvatar } from './use-smile-id-sample-avatar';
import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { smileCardStrokeWidth, smileProfileHues } from '../smile-product-hues';
import { atSize } from '../theme/smile-type';
import { smileStrokeOverlap } from './use-smile-id-sample-section-surface';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const ROW_PADDING_X = 14;
const ROW_TITLE_SIZE = 14.5;

type Props = {
  organisation: string;
  supportingText: string;
  initials: string;
  selected: boolean;
  onPress: () => void;
  /// The same default the avatar has: a second one drew one profile in two colours.
  avatarColor?: string;
  testID?: string;
  trailing?: ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// An organisation and a supporting line — the person on the switch sheet, "Tap to configure" in settings.
export const UseSmileIDSampleProfileRow = ({
  organisation,
  supportingText,
  initials,
  selected,
  onPress,
  avatarColor,
  testID,
  trailing,
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
        styles.card,
        {
          borderRadius: theme.shapes.card,
          backgroundColor: selected ? theme.colors.surfaceTile : theme.colors.surface,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
        },
        style,
      ]}
    >
      <View
        style={[
          styles.row,
          smileStrokeOverlap,
          {
            minHeight: theme.dimens.space[64],
            paddingHorizontal: ROW_PADDING_X,
            paddingVertical: theme.dimens.spacing.sm,
            columnGap: theme.dimens.spacing.sm,
          },
        ]}
      >
        <UseSmileIDSampleAvatar
          initials={initials}
          size={theme.dimens.size['control-md']}
          containerColor={avatarColor ?? smileProfileHues[0]}
        />
        <View style={[styles.text, { rowGap: theme.dimens.spacing.xxs }]}>
          <Text
            style={[
              atSize(theme.type.textStyleBodyStrong, ROW_TITLE_SIZE),
              { color: theme.colors.textTitle },
            ]}
          >
            {organisation}
          </Text>
          <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>
            {supportingText}
          </Text>
        </View>
        {trailing ??
          (selected ? (
            <View
              style={[
                styles.check,
                { width: theme.dimens.size['icon-md'], height: theme.dimens.size['icon-md'] },
              ]}
            >
              <UseSmileIDSampleIcon name="check" tint={theme.colors.primary} />
            </View>
          ) : null)}
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  card: { alignSelf: 'stretch', overflow: 'hidden' },
  row: { alignItems: 'center', flexDirection: 'row' },
  text: { flex: 1 },
  check: { alignItems: 'center', justifyContent: 'center' },
});
