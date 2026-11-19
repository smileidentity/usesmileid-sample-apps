import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import { insetForBorder } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  caption: string;
  message: string;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// The app's neutral banner, as the session-ended card draws it: an all-caps caption over the message.
export const UseSmileIDSampleBanner = ({ caption, message, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  return (
    <View
      testID={testID}
      style={[
        styles.card,
        {
          minHeight: theme.dimens.space[64],
          borderRadius: theme.shapes.card,
          backgroundColor: theme.colors.surfaceMuted,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
          padding: insetForBorder(theme.dimens.spacing.md, smileCardStrokeWidth),
          rowGap: theme.dimens.spacing.xxs,
        },
        style,
      ]}
    >
      <Text style={[theme.type.textStyleOverline, { color: theme.colors.banner.text }]}>
        {caption.toLocaleUpperCase()}
      </Text>
      <Text style={[theme.type.textStyleBodyStrong, { color: theme.colors.banner.title }]}>{message}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { alignSelf: 'stretch' },
});
