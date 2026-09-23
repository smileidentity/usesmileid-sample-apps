import { View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's glyph box.
const SCAN_GLYPH_SIZE = 279;

type Props = {
  size?: number;
  /// The caller's tint, which carries the scanner's state.
  tint?: string;
  style?: StyleProp<ViewStyle>;
};

/// The design's scan glyph, standing in for a live reticle.
export const UseSmileIDSampleScanGlyph = ({ size = SCAN_GLYPH_SIZE, tint, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  return (
    <View style={style} pointerEvents="none">
      <UseSmileIDSampleIcon name="scanGlyph" tint={tint ?? theme.colors.textTitle} size={size} />
    </View>
  );
};
