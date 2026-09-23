import { Text, type StyleProp, type TextStyle } from 'react-native';

import { smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  text: string;
  testID?: string;
  style?: StyleProp<TextStyle>;
};

/// The all-caps group heading above a section. Callers pass the text already cased, so no locale upper-casing.
export const UseSmileIDSampleSectionLabel = ({ text, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  return (
    <Text
      testID={testID}
      style={[
        // The design's Type/Label, which text-style.overline sets a point small and solid.
        atSize(theme.type.textStyleOverline, smileLabelSize),
        { letterSpacing: smileLabelTracking, color: theme.colors.textMuted },
        style,
      ]}
    >
      {text}
    </Text>
  );
};
