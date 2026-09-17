import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { lightColors } from '../tokens';

type Props = {
  /// Which environment a run submits to, which the token's api_url claim decides.
  environment: 'sandbox' | 'production';
  style?: StyleProp<ViewStyle>;
};

/// An environment pill: a status dot plus the environment name. Display-only, and no shipped screen renders it.
export const UseSmileIDSampleProfileEnvChip = ({ environment, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const dot =
    environment === 'sandbox'
      ? lightColors.color.feedback.warning.fill
      : lightColors.color.feedback.success.fill;

  return (
    <View
      testID={UseSmileIDSampleTestIds.ENV_CHIP}
      // Width is not fixed: Production is wider than Sandbox.
      style={[
        styles.chip,
        {
          backgroundColor: theme.colors.surfaceAlt,
          borderRadius: theme.dimens.radius.chip,
          paddingHorizontal: theme.dimens.spacing.sm,
          paddingVertical: theme.dimens.spacing.xxs,
          columnGap: theme.dimens.spacing.xxs,
          minHeight: theme.dimens.space[32],
        },
        style,
      ]}
    >
      <View
        style={{
          width: theme.dimens.spacing.xs,
          height: theme.dimens.spacing.xs,
          borderRadius: theme.dimens.spacing.xs / 2,
          backgroundColor: dot,
        }}
      />
      <Text style={[theme.type.textStyleCaption, { color: theme.colors.textTitle }]}>
        {environment === 'sandbox' ? 'Sandbox' : 'Production'}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  chip: { alignItems: 'center', alignSelf: 'flex-start', flexDirection: 'row' },
});
