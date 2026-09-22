import type { ReactNode } from 'react';
import { PixelRatio, Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import type { UseSmileIDSampleTopAppBarEmphasis } from '../model/use-smile-id-sample-app-bar-emphasis';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// Pinned, not a minimum: a longer title growing the bar drops the header lower on some screens than others.
const HEADER_ROW_HEIGHT = 40;
const TITLE_SIZE = 15;

type ButtonProps = {
  accessibilityLabel: string;
  onPress: () => void;
  emphasis?: UseSmileIDSampleTopAppBarEmphasis;
  testID?: string;
  glyph: (tint: string) => ReactNode;
};

/// One circular 40 app-bar control, with the platform expanding the touch target around it.
export const UseSmileIDSampleTopAppBarButton = ({
  accessibilityLabel,
  onPress,
  emphasis = 'Tonal',
  testID,
  glyph,
}: ButtonProps) => {
  const theme = useSmileIDSampleTheme();
  const paint = {
    Filled: { container: theme.colors.textTitle, tint: theme.colors.textInverse },
    Tonal: { container: theme.colors.surfaceTile, tint: theme.colors.textTitle },
    Destructive: { container: theme.colors.badge.errorBackground, tint: theme.colors.badge.errorText },
  }[emphasis];

  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onPress={onPress}
      hitSlop={HIT_SLOP}
      style={[
        styles.control,
        {
          width: theme.dimens.space[40],
          height: theme.dimens.space[40],
          borderRadius: theme.dimens.space[40] / 2,
          backgroundColor: paint.container,
        },
      ]}
    >
      {glyph(paint.tint)}
    </Pressable>
  );
};

type Props = {
  title: string;
  onBack: () => void;
  backAccessibilityLabel?: string;
  testID?: string;
  action?: ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// The pushed-screen app bar: a dark-filled circular back control, a title, and an optional trailing action.
export const UseSmileIDSampleTopAppBar = ({
  title,
  onBack,
  backAccessibilityLabel = 'Back',
  testID,
  action,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const rowHeight = HEADER_ROW_HEIGHT * Math.max(1, PixelRatio.getFontScale());

  return (
    <View
      testID={testID}
      style={[
        styles.bar,
        {
          paddingTop: insets.top,
          paddingHorizontal: theme.dimens.spacing.md,
          paddingBottom: theme.dimens.spacing.xs,
          columnGap: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      <View style={[styles.row, { minHeight: rowHeight, columnGap: theme.dimens.spacing.xs }]}>
        <UseSmileIDSampleTopAppBarButton
          accessibilityLabel={backAccessibilityLabel}
          onPress={onBack}
          emphasis="Filled"
          glyph={(tint) => <UseSmileIDSampleIcon name="arrowBack" tint={tint} />}
        />
        <Text
          // Wraps rather than caps: ellipsising a title is the clipping the predicate forbids.
          style={[
            atSize(theme.type.textStyleTitle, TITLE_SIZE),
            styles.title,
            { color: theme.colors.textTitle },
          ]}
        >
          {title}
        </Text>
        {/* Holds the action's width even with no action, so the title sits identically either way. */}
        {action ?? <View style={{ width: theme.dimens.space[40] }} />}
      </View>
    </View>
  );
};

const HIT_SLOP = 8;

const styles = StyleSheet.create({
  bar: { width: '100%' },
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  control: { alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1, textAlign: 'center' },
});
