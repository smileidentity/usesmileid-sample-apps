import { Text, type StyleProp, type TextStyle } from 'react-native';

import {
  smileSectionHeaderLineHeight,
  smileSectionHeaderSize,
  smileSectionHeaderWeight,
} from '../smile-product-hues';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  text: string;
  testID?: string;
  style?: StyleProp<TextStyle>;
};

/// Sentence-case headings, distinct from the all-caps section label.
export const UseSmileIDSampleSectionHeader = ({ text, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  return (
    <Text
      testID={testID}
      style={[
        atSize(
          atWeight(theme.type.textStyleHeadingSection, smileSectionHeaderWeight),
          smileSectionHeaderSize,
          smileSectionHeaderLineHeight,
        ),
        {
          color: theme.colors.offBlack,
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
