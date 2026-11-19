import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import { type UseSmileIDSampleBannerTone } from '../state/use-smile-id-sample-details-failure';
import { touchTargetStyle } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleButton } from './use-smile-id-sample-button';
import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';

type Props = {
  title: string;
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

/// The banner contract's leading edge.
const ACCENT_WIDTH = 3;

/// The design system's banner: a neutral surface with the tone's accent edge and glyph, a title over the message, and at most one action.
export const UseSmileIDSampleBanner = ({
  title,
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
        {actionLabel === undefined ? null : actionProminent ? (
          <View style={{ marginTop: theme.dimens.spacing.md - theme.dimens.spacing.xxs }}>
            <UseSmileIDSampleButton text={actionLabel} onPress={onAction} testID={actionTestID} />
          </View>
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
    </View>
  );
};

const styles = StyleSheet.create({
  card: { alignSelf: 'stretch', flexDirection: 'row', overflow: 'hidden' },
  body: { alignItems: 'flex-start', flex: 1, flexDirection: 'row' },
  text: { flex: 1 },
  textAction: { alignItems: 'center', alignSelf: 'flex-end', justifyContent: 'center' },
});
