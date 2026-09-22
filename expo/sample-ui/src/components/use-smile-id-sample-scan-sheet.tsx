import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from './use-smile-id-sample-button';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  onPaste: () => void;
  onSimulate: () => void;
  style?: StyleProp<ViewStyle>;
};

/// The scan screen's bottom sheet: a manual-entry row above the primary simulate action.
export const UseSmileIDSampleScanSheet = ({ onPaste, onSimulate, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      style={[
        styles.sheet,
        {
          backgroundColor: theme.colors.surface,
          borderTopLeftRadius: theme.shapes.card,
          borderTopRightRadius: theme.shapes.card,
          padding: theme.dimens.spacing.md,
          paddingBottom: theme.dimens.spacing.md + insets.bottom,
          rowGap: theme.dimens.spacing.sm,
        },
        style,
      ]}
    >
      <View
        testID={UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY}
        style={[
          styles.row,
          {
            minHeight: theme.dimens.size['control-md'],
            borderRadius: theme.dimens.radius.field,
            backgroundColor: theme.colors.surfaceAlt,
            paddingHorizontal: theme.dimens.spacing.md,
            paddingVertical: theme.dimens.spacing.xs,
            columnGap: theme.dimens.spacing.sm,
          },
        ]}
      >
        <Text style={[theme.type.textStyleBodySm, styles.label, { color: theme.colors.textTitle }]}>
          Or enter token manually
        </Text>
        <Pressable
          testID={UseSmileIDSampleTestIds.TOKEN_PASTE}
          accessibilityRole="button"
          onPress={onPaste}
          // Laid out at the platform's touch target, as Compose's minimum size does.
          style={[styles.action, { minHeight: theme.dimens.touchTarget, minWidth: theme.dimens.touchTarget, paddingHorizontal: theme.dimens.spacing.xs }]}
        >
          <Text style={[theme.type.textStyleButtonSm, { color: theme.colors.primary }]}>Paste</Text>
        </Pressable>
      </View>
      {/* A first-class feature, not debug scaffolding: it is what makes token flows testable with no QR source. */}
      <UseSmileIDSampleButton
        text="Simulate a successful scan"
        onPress={onSimulate}
        testID={UseSmileIDSampleTestIds.TOKEN_SIMULATE}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  sheet: { width: '100%' },
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  label: { flex: 1 },
  action: { alignItems: 'center', justifyContent: 'center' },
});
