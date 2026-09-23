import { Text, type StyleProp, type TextStyle } from 'react-native';

import { smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  relative: string;
  absolute: string;
  testID?: string;
  style?: StyleProp<TextStyle>;
};

/// The date separator in the verifications list. Both halves arrive formatted, because both are locale-dependent.
export const UseSmileIDSampleDateGroupHeader = ({ relative, absolute, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  // A day with no relative word renders its absolute date alone, never the date twice.
  const text = relative.length === 0 ? absolute : `${relative}  ·  ${absolute}`;

  return (
    <Text
      testID={testID}
      style={[
        atSize(theme.type.textStyleOverline, smileLabelSize),
        {
          letterSpacing: smileLabelTracking,
          color: theme.colors.textMuted,
          paddingVertical: theme.dimens.spacing.xs,
          width: '100%',
        },
        style,
      ]}
    >
      {text}
    </Text>
  );
};
