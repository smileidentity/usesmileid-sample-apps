import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import { type UseSmileIDSampleBannerTone } from '../state/use-smile-id-sample-details-failure';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';

type Props = {
  title: string;
  message: string;
  tone: UseSmileIDSampleBannerTone;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// The banner contract's leading edge.
const ACCENT_WIDTH = 3;

/// The design system's banner: a neutral surface with the tone's accent edge and glyph, and a title over the message.
export const UseSmileIDSampleBanner = ({
  title,
  message,
  tone,
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const accent = tone === 'warning' ? theme.colors.banner.warningAccent : theme.colors.banner.errorAccent;
  return (
    <View
      testID={testID}
      style={[
        styles.card,
        {
          borderRadius: theme.shapes.field,
          backgroundColor: theme.colors.banner.background,
          // The card stroke, as the session-ended banner takes: banner.border carries one light value in both schemes.
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
        },
        style,
      ]}
    >
      <View style={{ width: ACCENT_WIDTH, backgroundColor: accent }} />
      <View style={[styles.body, { padding: theme.dimens.spacing.md, columnGap: theme.dimens.spacing.sm }]}>
        <UseSmileIDSampleIcon name={tone === 'warning' ? 'warning' : 'cancel'} tint={accent} />
        <View style={[styles.text, { rowGap: theme.dimens.spacing.xxs }]}>
          <Text style={[theme.type.textStyleBodyStrong, { color: theme.colors.banner.title }]}>{title}</Text>
          <Text style={[theme.type.textStyleBodySm, { color: theme.colors.banner.text }]}>{message}</Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { alignSelf: 'stretch', flexDirection: 'row', overflow: 'hidden' },
  body: { alignItems: 'flex-start', flex: 1, flexDirection: 'row' },
  text: { flex: 1 },
});
