import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { atSize, atWeight } from '../theme/smile-type';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const COUNT_SIZE = 14;
const HINT_SIZE = 11.5;
const REMOVE_SIZE = 13.5;
/// Dimmed rather than recoloured, so a disabled action still reads as the strong one.
const DISABLED_OPACITY = 0.45;

type Props = {
  selectedCount: number;
  onRemove: () => void;
  style?: StyleProp<ViewStyle>;
};

/// Replaces the nav bar in select mode. The count is its own node, so a flow asserts equality rather than parsing prose.
export const UseSmileIDSampleSelectionBar = ({ selectedCount, onRemove, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      testID={UseSmileIDSampleTestIds.SELECTION_BAR}
      style={[
        styles.bar,
        {
          backgroundColor: theme.colors.surface,
          // A top edge only: a border would outline all four sides of a full-bleed bar.
          borderTopWidth: theme.dimens.borderWidth.hairline,
          borderTopColor: theme.colors.border,
        },
        style,
      ]}
    >
      <View
        style={[
          styles.row,
          {
            paddingBottom: insets.bottom,
            paddingHorizontal: theme.dimens.spacing.md,
            paddingTop: theme.dimens.spacing.sm,
            columnGap: theme.dimens.spacing.sm,
            rowGap: theme.dimens.spacing.xs,
          },
        ]}
      >
        <View style={{ rowGap: theme.dimens.spacing.xxs }}>
          <Text
            testID={UseSmileIDSampleTestIds.SELECTION_COUNT}
            style={[
              atSize(atWeight(theme.type.textStyleBodyStrong, 700), COUNT_SIZE),
              { color: theme.colors.textTitle },
            ]}
          >
            {`${selectedCount} selected`}
          </Text>
          <Text style={[atSize(theme.type.textStyleBodySm, HINT_SIZE), { color: theme.colors.textMuted }]}>
            {selectedCount === 0 ? 'Tap rows to select' : 'Tap `Hide from List` to confirm'}
          </Text>
        </View>
        <RemoveAction enabled={selectedCount > 0} onRemove={onRemove} />
      </View>
    </View>
  );
};

/// The action reads Hide from List, never Remove or Delete: nothing is deleted at the API.
const RemoveAction = ({ enabled, onRemove }: { enabled: boolean; onRemove: () => void }) => {
  const theme = useSmileIDSampleTheme();
  return (
    <Pressable
      testID={UseSmileIDSampleTestIds.SELECTION_REMOVE}
      accessibilityRole="button"
      accessibilityState={{ disabled: !enabled }}
      disabled={!enabled}
      onPress={onRemove}
      style={[
        styles.remove,
        {
          opacity: enabled ? 1 : DISABLED_OPACITY,
          borderRadius: theme.dimens.radius.control,
          backgroundColor: theme.colors.badge.errorBackground,
          minHeight: theme.dimens.space[40],
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.spacing.xs,
          columnGap: theme.dimens.spacing.xs,
        },
      ]}
    >
      <UseSmileIDSampleIcon
        name="trash"
        tint={theme.colors.badge.errorText}
        size={theme.dimens.size['icon-sm']}
      />
      <Text
        style={[
          atSize(atWeight(theme.type.textStyleBodyStrong, 700), REMOVE_SIZE),
          { color: theme.colors.badge.errorText },
        ]}
      >
        Hide from List
      </Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  bar: { width: '100%' },
  // Both children keep their natural width, so a row too narrow for them wraps instead of crushing the text.
  row: {
    alignItems: 'center',
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    width: '100%',
  },
  remove: { alignItems: 'center', flexDirection: 'row' },
});
