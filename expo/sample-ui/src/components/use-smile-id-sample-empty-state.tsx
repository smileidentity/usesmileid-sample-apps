import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  text: string;
  supportingText?: string;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// What a list says when it has nothing to show. Not in the design; the supporting line is only where the reader can act.
export const UseSmileIDSampleEmptyState = ({ text, supportingText, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <View
      testID={testID}
      style={[
        styles.container,
        {
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.space[32],
          rowGap: theme.dimens.spacing.xxs,
        },
        style,
      ]}
    >
      <Text style={[theme.type.textStyleBodyStrong, styles.centred, { color: theme.colors.textBody }]}>
        {text}
      </Text>
      {supportingText !== undefined ? (
        <Text style={[theme.type.textStyleCaption, styles.centred, { color: theme.colors.textMuted }]}>
          {supportingText}
        </Text>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { alignItems: 'center', width: '100%' },
  centred: { textAlign: 'center' },
});
