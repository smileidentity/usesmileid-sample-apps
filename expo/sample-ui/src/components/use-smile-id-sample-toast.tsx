import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The snackbar's own metrics, which land between the scale steps — spec/components.json → Toast.
const SNACKBAR_RADIUS = 12;
const SNACKBAR_HEIGHT = 46;
const SNACKBAR_PADDING_Y = 13;
const SNACKBAR_TEXT_SIZE = 13.5;
const SNACKBAR_ACTION_SIZE = 14;

type Props = {
  message: string;
  actionLabel?: string;
  onAction?: () => void;
  style?: StyleProp<ViewStyle>;
};

/// A snackbar: a dark bar with a message and an underlined action, spanning the width it is given.
export const UseSmileIDSampleToast = ({ message, actionLabel, onAction, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const showAction = actionLabel !== undefined && onAction !== undefined;

  return (
    <View
      testID={UseSmileIDSampleTestIds.TOAST}
      style={[
        styles.bar,
        theme.dimens.elevation.floating,
        {
          minHeight: SNACKBAR_HEIGHT,
          borderRadius: SNACKBAR_RADIUS,
          backgroundColor: theme.colors.textTitle,
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: SNACKBAR_PADDING_Y,
          columnGap: theme.dimens.spacing.sm,
          rowGap: theme.dimens.space[4],
        },
        style,
      ]}
    >
      <Text
        style={[
          atSize(atWeight(theme.type.bannerTextFont, 500), SNACKBAR_TEXT_SIZE),
          styles.message,
          { color: theme.colors.background },
        ]}
      >
        {message}
      </Text>
      {showAction ? (
        <Pressable
          testID={UseSmileIDSampleTestIds.TOAST_UNDO}
          accessibilityRole="button"
          onPress={onAction}
          // Widened, not squared off: a 48-high action inflates the 46 bar to 72. minWidth is
          // border-box here, so the padding sits inside it and the Compose twin's max() matches.
          style={[
            styles.action,
            { minWidth: theme.dimens.size['control-md'], paddingHorizontal: theme.dimens.spacing.xs },
          ]}
        >
          <Text
            numberOfLines={1}
            style={[
              atSize(atWeight(theme.type.linkFont, 600), SNACKBAR_ACTION_SIZE),
              styles.actionLabel,
              { color: theme.colors.background },
            ]}
          >
            {actionLabel}
          </Text>
        </Pressable>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  // Wrapping so a cramped action moves onto its own line whole; a plain row breaks "Undo" in half.
  bar: { alignItems: 'center', flexDirection: 'row', flexWrap: 'wrap', width: '100%' },
  message: { flexBasis: 'auto', flexGrow: 1, flexShrink: 1 },
  action: { alignItems: 'center', justifyContent: 'center' },
  actionLabel: { textAlign: 'center', textDecorationLine: 'underline' },
});
