import { View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's own glyph box, as the Compose app draws it.
const SCAN_GLYPH_SIZE = 279;

type Props = {
  size?: number;
  /// The reticle carries the scanner's state over a live camera, so its tint is the caller's.
  tint?: string;
  style?: StyleProp<ViewStyle>;
};

/// The design's scan glyph — corner brackets and a faint sweep line — standing in for a live reticle.
export const UseSmileIDSampleScanGlyph = ({ size = SCAN_GLYPH_SIZE, tint, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  return (
    <View style={style} pointerEvents="none">
      <UseSmileIDSampleIcon name="scanGlyph" tint={tint ?? theme.colors.textTitle} size={size} />
    </View>
  );
};
