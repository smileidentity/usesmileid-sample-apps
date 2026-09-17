import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  onScan: () => void;
  style?: StyleProp<ViewStyle>;
};

/// A neutral grey card that replaces the session card once the session expires — not a warning-accented banner.
export const UseSmileIDSampleSessionEndedBanner = ({ onScan, style }: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      testID={UseSmileIDSampleTestIds.SESSION_ENDED_BANNER}
      // Matches the session card's height so the two swap without the layout moving.
      style={[
        styles.card,
        {
          minHeight: theme.dimens.space[64],
          borderRadius: theme.shapes.card,
          backgroundColor: theme.colors.surfaceMuted,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
          padding: theme.dimens.spacing.md,
          columnGap: theme.dimens.spacing.sm,
          rowGap: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      <View style={[styles.text, { rowGap: theme.dimens.spacing.xxs }]}>
        <Text style={[theme.type.textStyleOverline, { color: theme.colors.textTitle }]}>
          TOKEN SESSION ENDED
        </Text>
        <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>
          Scan a token to relink
        </Text>
      </View>
      <Pressable
        accessibilityRole="button"
        onPress={onScan}
        // A text action, expanded to the platform target with slop rather than a taller banner.
        hitSlop={12}
      >
        <Text style={[theme.type.textStyleButtonSm, { color: theme.colors.primary }]}>Scan</Text>
      </Pressable>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { alignItems: 'center', flexDirection: 'row', flexWrap: 'wrap', width: '100%' },
  text: { flex: 1 },
});
