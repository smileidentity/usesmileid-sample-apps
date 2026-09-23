import type { ReactNode } from 'react';
import { PixelRatio, Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import {
  smileCardFamilyWeight,
  smileCardStrokeWidth,
  smileCardTitleTracking,
  type SmileProductHue,
} from '../smile-product-hues';
import { smileStrokeOverlap } from '../theme/smile-compose-layout';
import { smileInkOn, smileMix, smileWithAlpha } from '../theme/smile-color-math';
import { lightColors } from '../tokens';
import { atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The smallest size the two-line label may shrink to, as Compose's autosize floor.
const CARD_LABEL_MIN = 13;
const SCRIM_ALPHA = 0.16;
const GHOST_ALPHA = 0.1;

type Props = {
  title: string;
  family: string;
  onPress: () => void;
  hue: SmileProductHue;
  enabled?: boolean;
  testID?: string;
  icon?: (tint: string) => ReactNode;
  ghost?: (tint: string) => ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// A product tile: a gradient in the product's hue, a hairline stroke, its icon as a watermark.
export const UseSmileIDSampleProductCard = ({
  title,
  family,
  onPress,
  hue,
  enabled = true,
  testID,
  icon,
  ghost,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  // A hue is the same in both schemes, so anything drawn on it resolves from the light one.
  const tile = enabled ? lightColors.color.surface : theme.colors.surface;
  // Every card's text and arrow are white, per the frame: consistency across the six beats
  // per-card contrast, and the fix for the light fills belongs in the fill.
  const content = enabled ? lightColors.color.text.inverse : theme.colors.textMuted;
  // The two marks the design draws at a fixed colour DO adapt, because one fixed value leaves the
  // go pill invisible on the darkest card and the ghost invisible on the lightest.
  const ghostInk = smileInkOn(hue.from);
  const goScrim = enabled ? smileInkOn(gradientEnd(hue)) : theme.colors.textMuted;
  const minHeight = theme.dimens.space[64] * 2 + theme.dimens.space[20];

  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityState={{ disabled: !enabled }}
      disabled={!enabled}
      onPress={onPress}
      style={[
        styles.card,
        {
          minHeight,
          borderRadius: theme.shapes.card,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
        },
        style,
      ]}
    >
      {enabled ? (
        <HueFill hue={hue} />
      ) : (
        <View style={[StyleSheet.absoluteFill, { backgroundColor: theme.colors.surfaceMuted }]} />
      )}
      {ghost ? (
        <View
          style={[
            styles.ghost,
            { right: -theme.dimens.spacing.md, top: -theme.dimens.spacing.xs },
          ]}
        >
          {ghost(smileWithAlpha(ghostInk, GHOST_ALPHA))}
        </View>
      ) : null}
      <View style={[smileStrokeOverlap, { padding: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.lg }]}>
        <View
          style={[
            styles.tile,
            { width: theme.dimens.space[40], height: theme.dimens.space[40], borderRadius: theme.shapes.tile, backgroundColor: tile },
          ]}
        >
          {icon ? icon(hue.cardIcon) : <UseSmileIDSampleIcon name="productMark" tint={hue.cardIcon} />}
        </View>
        <View style={styles.footer}>
          <CardLabel title={title} family={family} color={content} />
          <View
            style={[
              styles.go,
              {
                width: theme.dimens.size['icon-lg'],
                height: theme.dimens.size['icon-lg'],
                borderRadius: theme.dimens.size['icon-lg'] / 2,
                backgroundColor: smileWithAlpha(goScrim, SCRIM_ALPHA),
              },
            ]}
          >
            <UseSmileIDSampleIcon name="arrowForward" tint={content} size={theme.dimens.size['icon-sm']} />
          </View>
        </View>
      </View>
    </Pressable>
  );
};

/// The design runs the outer stop past the card's edge, and an SVG stop must land inside 0..1 — so the
/// last stop is the colour the gradient has actually reached by the edge, not the one it never gets to.
const gradientEnd = (hue: SmileProductHue): string =>
  hue.stopEnd > 1 ? smileMix(hue.from, hue.to, (1 - hue.stopStart) / (hue.stopEnd - hue.stopStart)) : hue.to;

/// Drawn as SVG rather than with a gradient package: react-native-svg is already an SDK peer.
const HueFill = ({ hue }: { hue: SmileProductHue }) => (
  <Svg style={StyleSheet.absoluteFill} width="100%" height="100%">
    <Defs>
      <LinearGradient id="hue" x1="0" y1="0" x2="1" y2="1">
        <Stop offset={hue.stopStart} stopColor={hue.from} stopOpacity={hue.fromAlpha} />
        <Stop offset={Math.min(hue.stopEnd, 1)} stopColor={gradientEnd(hue)} stopOpacity={hue.toAlpha} />
      </LinearGradient>
    </Defs>
    <Rect x="0" y="0" width="100%" height="100%" fill="url(#hue)" />
  </Svg>
);

/// The title and family as two runs. Above the design's scale the label wraps, because a capped line count clips.
const CardLabel = ({ title, family, color }: { title: string; family: string; color: string }) => {
  const theme = useSmileIDSampleTheme();
  const fitsTwoLines = PixelRatio.getFontScale() <= 1;
  return (
    <Text
      numberOfLines={fitsTwoLines ? 2 : undefined}
      // Compose's step-based autosize: the title shrinks towards 13 before either run is cut.
      adjustsFontSizeToFit={fitsTwoLines}
      minimumFontScale={CARD_LABEL_MIN / theme.type.textStyleBodyStrong.fontSize}
      style={[
        theme.type.textStyleBodyStrong,
        styles.label,
        { color, letterSpacing: smileCardTitleTracking },
      ]}
    >
      {title}
      {'\n'}
      <Text
        style={[
          atWeight(theme.type.textStyleCaption, smileCardFamilyWeight),
          { color },
        ]}
      >
        {family}
      </Text>
    </Text>
  );
};

const styles = StyleSheet.create({
  // Clipped, so the ghost watermark bleeds off the corner rather than growing the card.
  card: { overflow: 'hidden', width: '100%' },
  ghost: { position: 'absolute' },
  tile: { alignItems: 'center', justifyContent: 'center' },
  footer: { alignItems: 'flex-end', flexDirection: 'row', justifyContent: 'space-between', width: '100%' },
  label: { flex: 1 },
  go: { alignItems: 'center', justifyContent: 'center' },
});
