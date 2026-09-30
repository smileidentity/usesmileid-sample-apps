import Svg, { Path } from 'react-native-svg';

import { smileIcons, type SmileIcon, type SmileIconName } from '../smile-icons';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  name: SmileIconName;
  /// Null draws a two-tone mark in its own colours.
  tint: string | null;
  size?: number;
};

/// One mark from `design/icons/`, tinted by its caller. Decorative: the enclosing control carries the label.
export const UseSmileIDSampleIcon = ({ name, tint, size }: Props) => {
  const theme = useSmileIDSampleTheme();
  const icon: SmileIcon = smileIcons[name];
  const box = size ?? theme.dimens.size['icon-md'];

  return (
    <Svg
      width={box}
      height={box}
      viewBox={`${icon.minX} ${icon.minY} ${icon.width} ${icon.height}`}
      fill="none"
    >
      {icon.parts.map((part, index) => {
        const paint = tint ?? part.colour ?? theme.colors.textTitle;
        return (
        <Path
          key={index}
          d={part.d}
          opacity={part.opacity}
          {...(part.paint.kind === 'fill'
            ? { fill: paint }
            : {
                stroke: paint,
                strokeWidth: part.paint.width,
                strokeLinecap: part.paint.round ? ('round' as const) : ('butt' as const),
                strokeLinejoin: part.paint.round ? ('round' as const) : ('miter' as const),
                fill: 'none',
              })}
        />
        );
      })}
    </Svg>
  );
};

/// The marks a composite reaches for by role rather than by file name, so a rename lands in one place.
export const UseSmileIDSampleMarkNames = {
  arrowBack: 'arrowBack',
  arrowForward: 'arrowForward',
  chevron: 'chevron',
  chevronDown: 'chevronDown',
  check: 'check',
  copy: 'copy',
  plus: 'plus',
  trash: 'trash',
  flash: 'flash',
  scanMark: 'tokenScan',
  productMark: 'productMark',
} as const satisfies Readonly<Record<string, SmileIconName>>;
