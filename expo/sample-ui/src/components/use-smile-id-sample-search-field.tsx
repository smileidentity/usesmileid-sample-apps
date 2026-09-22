import { useState } from 'react';
import { StyleSheet, TextInput, View, type StyleProp, type ViewStyle } from 'react-native';
import Svg, { Circle, Line } from 'react-native-svg';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  query: string;
  onQueryChange: (query: string) => void;
  placeholder?: string;
  testID?: string;
  style?: StyleProp<ViewStyle>;
};

/// The sheet search field. The glyph is drawn because `design/icons/` carries no search mark and this platform has no system symbol to borrow.
export const UseSmileIDSampleSearchField = ({
  query,
  onQueryChange,
  placeholder = '',
  testID,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const [focused, setFocused] = useState(false);
  const borderWidth = focused ? theme.dimens.borderWidth.thin : theme.dimens.borderWidth.hairline;

  return (
    <View
      style={[
        styles.row,
        {
          minHeight: theme.dimens.size['control-md'],
          backgroundColor: theme.colors.search.background,
          borderRadius: theme.dimens.radius.field,
          borderWidth,
          borderColor: focused ? theme.colors.search.borderFocus : theme.colors.search.border,
          // Compose draws the border over the padding; here it sits inside the box, so it comes off the padding.
          paddingHorizontal: theme.dimens.spacing.md - borderWidth,
          paddingVertical: theme.dimens.spacing.sm - borderWidth,
          columnGap: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      <MagnifierGlyph tint={theme.colors.search.icon} size={theme.dimens.size['icon-md']} />
      <TextInput
        testID={testID}
        value={query}
        onChangeText={onQueryChange}
        placeholder={placeholder}
        placeholderTextColor={theme.colors.search.placeholder}
        selectionColor={theme.colors.search.borderFocus}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={[theme.type.searchFont, styles.input, { color: theme.colors.search.text }]}
      />
    </View>
  );
};

/// The same geometry the Compose twin draws, so the two apps' fields read identically.
const MagnifierGlyph = ({ tint, size }: { tint: string; size: number }) => {
  const stroke = 1.5;
  const radius = size * 0.32;
  const centre = radius + stroke;
  return (
    <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <Circle cx={centre} cy={centre} r={radius} stroke={tint} strokeWidth={stroke} fill="none" />
      <Line
        x1={centre + radius * 0.7}
        y1={centre + radius * 0.7}
        x2={size - stroke}
        y2={size - stroke}
        stroke={tint}
        strokeWidth={stroke}
        strokeLinecap="round"
      />
    </Svg>
  );
};

const styles = StyleSheet.create({
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  input: { flex: 1, padding: 0 },
});
