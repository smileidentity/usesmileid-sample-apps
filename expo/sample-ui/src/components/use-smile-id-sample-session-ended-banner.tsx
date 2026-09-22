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
          // Compose draws the stroke over the padding; here it sits inside the box, so it comes off the padding.
          padding: theme.dimens.spacing.md - smileCardStrokeWidth,
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
        // Laid out at the platform's touch target, as Compose's minimum size does.
        style={[styles.action, { minHeight: theme.dimens.touchTarget, minWidth: theme.dimens.touchTarget, paddingHorizontal: theme.dimens.spacing.xs }]}
      >
        <Text style={[theme.type.textStyleButtonSm, { color: theme.colors.primary }]}>Scan</Text>
      </Pressable>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { alignItems: 'center', alignSelf: 'stretch', flexDirection: 'row', flexWrap: 'wrap' },
  text: { flex: 1 },
  action: { alignItems: 'center', justifyContent: 'center' },
});
