import { Platform, Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleTokenRing } from './use-smile-id-sample-token-ring';
import { smileIDSampleNavItems, type UseSmileIDSampleNavItem } from '../model/use-smile-id-sample-nav-item';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const TAB_ICON_SIZE = 21;
const TOKEN_SIZE = 58;
const TOKEN_LABEL_SIZE = 8.5;
/// The ring is painted outside the button's bounds: at 68 in the layout it pushed the bar off a 393 screen.
const RING_BLEED = 5;

type Props = {
  selectedId: string;
  onSelect: (item: UseSmileIDSampleNavItem) => void;
  onTokenPress: () => void;
  /// 1 fresh to 0 expired, from the session's deadline rather than an animation.
  sessionProgress?: number | null;
  style?: StyleProp<ViewStyle>;
};

/// Android's BAR_ELEVATION: the Compose bar's `shadowElevation`, 8dp, since a tinted token shadow draws almost nothing there.
export const SMILE_NAV_BAR_ELEVATION = 8;

/// The Compose elevation on Android and the design's floating shadow token on iOS.
const floatingShadow = (theme: ReturnType<typeof useSmileIDSampleTheme>): ViewStyle =>
  Platform.OS === 'android' ? { elevation: SMILE_NAV_BAR_ELEVATION } : theme.dimens.elevation.floating;

/// A floating pill of three tabs, plus a detached token button that navigates rather than switching tab.
export const UseSmileIDSampleNavBar = ({
  selectedId,
  onSelect,
  onTokenPress,
  sessionProgress,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      style={[
        styles.bar,
        {
          paddingBottom: insets.bottom + theme.dimens.spacing.sm,
          paddingHorizontal: theme.dimens.spacing.md,
          paddingTop: theme.dimens.spacing.sm,
          columnGap: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      <View
        // Takes all the space the token button leaves, so the three tabs are equal thirds of it.
        style={[
          styles.pill,
          floatingShadow(theme),
          {
            backgroundColor: theme.colors.navBar,
            borderRadius: theme.shapes.pill,
            paddingHorizontal: theme.dimens.spacing.xs,
            paddingVertical: theme.dimens.spacing.xxs,
          },
        ]}
      >
        {smileIDSampleNavItems.map((item) => (
          <NavBarTab
            key={item.id}
            item={item}
            selected={item.id === selectedId}
            onPress={() => onSelect(item)}
          />
        ))}
      </View>
      <TokenAffordance progress={sessionProgress ?? null} onPress={onTokenPress} />
    </View>
  );
};

const NavBarTab = ({
  item,
  selected,
  onPress,
}: {
  item: UseSmileIDSampleNavItem;
  selected: boolean;
  onPress: () => void;
}) => {
  const theme = useSmileIDSampleTheme();
  // Unselected takes the warm strong foreground, not color.text.muted.
  const tint = selected ? theme.colors.primary : theme.colors.offBlack;

  return (
    <Pressable
      testID={item.testID}
      accessibilityRole="tab"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[styles.tab, { padding: theme.dimens.spacing.xs, rowGap: theme.dimens.spacing.xxs }]}
    >
      <UseSmileIDSampleIcon name={item.icon} tint={tint} size={TAB_ICON_SIZE} />
      <Text style={[theme.type.textStyleOverline, styles.tabLabel, { color: tint }]}>{item.label}</Text>
    </Pressable>
  );
};

const TokenAffordance = ({ progress, onPress }: { progress: number | null; onPress: () => void }) => {
  const theme = useSmileIDSampleTheme();
  const ringSize = TOKEN_SIZE + RING_BLEED * 2;

  return (
    <View style={styles.token}>
      {progress !== null ? (
        <UseSmileIDSampleTokenRing
          progress={progress}
          size={ringSize}
          style={[styles.ring, { top: -RING_BLEED, left: -RING_BLEED }]}
        />
      ) : null}
      <Pressable
        testID={UseSmileIDSampleTestIds.NAV_TOKEN}
        accessibilityRole="button"
        accessibilityLabel="Token"
        onPress={onPress}
        // A minimum rather than a fixed box, so enlarged type grows it instead of clipping "Token".
        style={[
          styles.tokenButton,
          floatingShadow(theme),
          {
            minWidth: TOKEN_SIZE,
            minHeight: TOKEN_SIZE,
            borderRadius: TOKEN_SIZE / 2,
            backgroundColor: theme.colors.navBar,
          },
        ]}
      >
        <UseSmileIDSampleIcon
          name="tokenScan"
          tint={theme.colors.offBlack}
          size={theme.dimens.size['icon-sm']}
        />
        <Text
          style={[atSize(theme.type.textStyleOverline, TOKEN_LABEL_SIZE), { color: theme.colors.offBlack }]}
        >
          Token
        </Text>
      </Pressable>
    </View>
  );
};

const styles = StyleSheet.create({
  bar: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  pill: { alignItems: 'center', flexDirection: 'row', flex: 1 },
  tab: { alignItems: 'center', flex: 1 },
  tabLabel: { textAlign: 'center' },
  token: { alignItems: 'center', justifyContent: 'center' },
  ring: { position: 'absolute' },
  tokenButton: { alignItems: 'center', justifyContent: 'center' },
});
