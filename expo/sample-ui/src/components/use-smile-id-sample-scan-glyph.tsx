import { View, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Path } from 'react-native-svg';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

const STROKE = 3;
/// How far along each edge a bracket runs, as a fraction of the frame.
const ARM = 0.22;

type Props = {
  size?: number;
  style?: StyleProp<ViewStyle>;
};

/// The four corner brackets the design shows instead of a live reticle; the sweep line is the hidden state.
export const UseSmileIDSampleScanGlyph = ({ size, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const box = size ?? theme.dimens.space[64] * 4;
  const inset = STROKE;
  const far = box - inset;
  const arm = box * ARM;
  const brackets = [
    `M${inset} ${inset + arm} L${inset} ${inset} L${inset + arm} ${inset}`,
    `M${far - arm} ${inset} L${far} ${inset} L${far} ${inset + arm}`,
    `M${far} ${far - arm} L${far} ${far} L${far - arm} ${far}`,
    `M${inset + arm} ${far} L${inset} ${far} L${inset} ${far - arm}`,
  ];

  return (
    <View style={[{ width: box, height: box }, style]} pointerEvents="none">
      <Svg width={box} height={box}>
        {brackets.map((d) => (
          <Path
            key={d}
            d={d}
            stroke={theme.colors.primary}
            strokeWidth={STROKE}
            strokeLinecap="round"
            strokeLinejoin="round"
            fill="none"
          />
        ))}
      </Svg>
    </View>
  );
};
