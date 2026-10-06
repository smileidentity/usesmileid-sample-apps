import { createContext, useContext, useMemo, type ReactNode } from 'react';
import { useColorScheme } from 'react-native';

import { smileDarkColors, smileLightColors, type SmileColors } from './smile-colors';
import { smileDimens, type SmileDimens } from './smile-dimens';
import { smileType, type SmileTextStyle, type SmileType } from './smile-type';
import { useSmileIDSampleRightToLeft } from '../use-smile-id-sample-strings-context';

/// One radius per named surface, fixing where the scale is applied rather than which value it is.
export const smileShapes = {
  card: smileDimens.radius.surface,
  tile: smileDimens.radius.lg,
  field: smileDimens.radius.field,
  pill: smileDimens.radius.pill,
  chip: smileDimens.radius.chip,
  sheet: smileDimens.radius.sheet,
} as const;

/// Everything a component resolves a value from, with the colours already chosen for the mode.
export type UseSmileIDSampleTheme = {
  readonly colors: SmileColors;
  readonly dimens: SmileDimens;
  readonly type: SmileType;
  readonly shapes: typeof smileShapes;
  readonly dark: boolean;
};

const lightTheme: UseSmileIDSampleTheme = {
  colors: smileLightColors,
  dimens: smileDimens,
  type: smileType,
  shapes: smileShapes,
  dark: false,
};

const darkTheme: UseSmileIDSampleTheme = { ...lightTheme, colors: smileDarkColors, dark: true };

const ThemeContext = createContext<UseSmileIDSampleTheme>(lightTheme);

/// Provides the theme, following the system scheme unless the host pins one.
/// iOS aligns natural text by the launch language, not React Native's forced direction, so every style says it.
const rightToLeftType = (type: SmileType): SmileType => {
  const styles: Record<string, SmileTextStyle> = {};
  for (const [name, style] of Object.entries(type)) styles[name] = { ...style, writingDirection: 'rtl' };
  return styles as SmileType;
};

export const UseSmileIDSampleThemeProvider = ({
  dark,
  children,
}: {
  dark?: boolean;
  children: ReactNode;
}) => {
  const scheme = useColorScheme();
  const isDark = dark ?? scheme === 'dark';
  const rightToLeft = useSmileIDSampleRightToLeft();
  const value = useMemo(() => {
    const base = isDark ? darkTheme : lightTheme;
    return rightToLeft ? { ...base, type: rightToLeftType(base.type) } : base;
  }, [isDark, rightToLeft]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

/// Token accessors for every component in this package.
export const useSmileIDSampleTheme = (): UseSmileIDSampleTheme => useContext(ThemeContext);
