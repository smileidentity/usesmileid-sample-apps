import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import {
  smileCardFamilyWeight,
  smileCardStrokeWidth,
  smileTokenSessionGradient,
  smileTokenSessionGradientAlpha,
} from '../smile-product-hues';
import { lightColors } from '../tokens';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const LABEL_TRACKING = 1;
const COUNTDOWN_SIZE = 24;

type Props = {
  sessionId: string;
  /// Arrives formatted, because the deadline is absolute and the ticking is the screen's.
  remaining: string;
  style?: StyleProp<ViewStyle>;
};

/// The active token session and its m:ss countdown, on a gradient that composites against the page.
export const UseSmileIDSampleSessionCard = ({ sessionId, remaining, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  // The gradient is scheme-independent, so its ink is too: colors.surface is #272a35 in dark.
  const ink = lightColors.color.text.inverse;

  return (
    <View
      testID={UseSmileIDSampleTestIds.SESSION_CARD}
      style={[
        styles.card,
        {
          borderRadius: theme.shapes.card,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
        },
        style,
      ]}
    >
      <Svg style={StyleSheet.absoluteFill} width="100%" height="100%">
        <Defs>
          <LinearGradient id="session" x1="0" y1="0" x2="1" y2="0">
            <Stop
              offset={0}
              stopColor={smileTokenSessionGradient[0]}
              stopOpacity={smileTokenSessionGradientAlpha[0]}
            />
            <Stop
              offset={1}
              stopColor={smileTokenSessionGradient[1]}
              stopOpacity={smileTokenSessionGradientAlpha[1]}
            />
          </LinearGradient>
        </Defs>
        <Rect x="0" y="0" width="100%" height="100%" fill="url(#session)" />
      </Svg>
      <View
        style={[
          styles.row,
          {
            minHeight: theme.dimens.space[64],
            padding: theme.dimens.spacing.md,
            columnGap: theme.dimens.spacing.sm,
            rowGap: theme.dimens.spacing.xs,
          },
        ]}
      >
        <View style={[styles.text, { rowGap: theme.dimens.spacing.xxs }]}>
          <Text style={[theme.type.textStyleOverline, { letterSpacing: LABEL_TRACKING, color: ink }]}>
            ACTIVE TOKEN SESSION
          </Text>
          <Text
            style={[
              theme.type.textStyleCaption,
              { fontWeight: String(smileCardFamilyWeight) as never, color: ink },
            ]}
          >
            {`Linked to session ${sessionId}`}
          </Text>
        </View>
        <Text
          testID={UseSmileIDSampleTestIds.SESSION_COUNTDOWN}
          // The one value that must stay whole, so the text beside it yields instead.
          numberOfLines={1}
          style={[theme.type.textStyleHeadingCard, { fontSize: COUNTDOWN_SIZE, color: ink }]}
        >
          {remaining}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { overflow: 'hidden', width: '100%' },
  row: { alignItems: 'center', flexDirection: 'row', flexWrap: 'wrap', width: '100%' },
  text: { flex: 1 },
});
