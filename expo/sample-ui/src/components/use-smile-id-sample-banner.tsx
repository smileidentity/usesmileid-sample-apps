import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import { type UseSmileIDSampleBannerTone } from '../state/use-smile-id-sample-details-failure';
import { touchTargetStyle } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleButton } from './use-smile-id-sample-button';
import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';

type Props = {
  message: string;
  tone: UseSmileIDSampleBannerTone;
  /// The one action's label; none draws no action.
  actionLabel?: string;
  onAction?: () => void;
  /// A full-width button when it moves the user on, a trailing text action when it only closes.
  actionProminent?: boolean;
  testID?: string;
  actionTestID?: string;
  style?: StyleProp<ViewStyle>;
};

/// The banner contract's leading bar.
const ACCENT_WIDTH = 4;

/// The design system's banner on the card surface: an accent bar and glyph, the message, and at most one action under it.
export const UseSmileIDSampleBanner = ({
  message,
  tone,
  actionLabel,
  onAction = () => {},
  actionProminent = true,
  testID,
  actionTestID,
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
          borderRadius: theme.shapes.card,
          backgroundColor: theme.colors.card.background,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
        },
        style,
      ]}
    >
      <View style={{ width: ACCENT_WIDTH, backgroundColor: accent }} />
      <View style={[styles.body, { padding: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.md }]}>
        <View style={[styles.message, { columnGap: theme.dimens.spacing.sm }]}>
          <UseSmileIDSampleIcon name={tone === 'warning' ? 'warning' : 'cancel'} tint={accent} />
          <Text style={[styles.text, theme.type.textStyleBody, { color: theme.colors.banner.title }]}>{message}</Text>
        </View>
        {actionLabel === undefined ? null : actionProminent ? (
          <UseSmileIDSampleButton text={actionLabel} onPress={onAction} testID={actionTestID} />
        ) : (
          <Pressable
            testID={actionTestID}
            accessibilityRole="button"
            onPress={onAction}
            style={[styles.textAction, touchTargetStyle(theme), { paddingHorizontal: theme.dimens.spacing.xs }]}
          >
            <Text style={[theme.type.linkFont, { color: theme.colors.primary }]}>{actionLabel}</Text>
          </Pressable>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { alignSelf: 'stretch', flexDirection: 'row', overflow: 'hidden' },
  body: { flex: 1 },
  message: { alignItems: 'flex-start', flexDirection: 'row' },
  text: { flex: 1 },
  textAction: { alignItems: 'center', alignSelf: 'flex-end', justifyContent: 'center' },
});
