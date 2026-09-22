import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleSectionLabel } from './use-smile-id-sample-section-label';
import { smileCardStrokeWidth } from '../smile-product-hues';
import { smileStrokeOverlap } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  label?: string;
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
};

/// The labelled rounded-hairline section card every detail and settings screen draws its rows on.
export const UseSmileIDSampleSectionSurface = ({ label, children, style }: Props) => {
  const theme = useSmileIDSampleTheme();

  return (
    <View style={[{ rowGap: theme.dimens.spacing.xs }, style]}>
      {label !== undefined ? <UseSmileIDSampleSectionLabel text={label} /> : null}
      <View
        style={[
          styles.card,
          {
            backgroundColor: theme.colors.surface,
            borderRadius: theme.shapes.card,
            borderWidth: smileCardStrokeWidth,
            borderColor: theme.colors.cardStroke,
          },
        ]}
      >
        <View style={smileStrokeOverlap}>{children}</View>
      </View>
    </View>
  );
};

/// The rule between two rows inside one card, which takes the card's own stroke rather than color.border.
export const UseSmileIDSampleRowDivider = () => {
  const theme = useSmileIDSampleTheme();
  return (
    <View style={{ backgroundColor: theme.colors.cardStroke, height: smileCardStrokeWidth }} />
  );
};

const styles = StyleSheet.create({
  // Clipped, so a row's own fill cannot square off the card's corners.
  card: { overflow: 'hidden', width: '100%' },
});
