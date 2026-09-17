import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  /// One cell per product, in design order; an odd count leaves the last slot blank.
  cells: readonly ReactNode[];
  style?: StyleProp<ViewStyle>;
};

/// Two columns with an empty slot when a section has an odd count, which is a layout affordance rather than a placeholder card.
export const UseSmileIDSampleProductGrid = ({ cells, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const rows: ReactNode[][] = [];
  for (let index = 0; index < cells.length; index += 2) {
    rows.push(cells.slice(index, index + 2));
  }

  return (
    <View style={[{ rowGap: theme.dimens.spacing.sm, width: '100%' }, style]}>
      {rows.map((row, rowIndex) => (
        // Stretched, so a two-line title beside a one-line title still yields two equal cards.
        <View key={rowIndex} style={[styles.row, { columnGap: theme.dimens.spacing.sm }]}>
          {row.map((cell, cellIndex) => (
            <View key={cellIndex} style={styles.cell}>
              {cell}
            </View>
          ))}
          {row.length === 1 ? <View style={styles.cell} /> : null}
        </View>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  row: { alignItems: 'stretch', flexDirection: 'row', width: '100%' },
  cell: { flex: 1 },
});
