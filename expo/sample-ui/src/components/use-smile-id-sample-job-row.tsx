import { PixelRatio, Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleStatusBadge } from './use-smile-id-sample-status-badge';
import {
  smileIDSampleProductHue,
  smileIDSampleProductIcon,
  type UseSmileIDSampleProduct,
} from '../model/use-smile-id-sample-product';
import type { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';
import { smileCardStrokeWidth } from '../smile-product-hues';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { smileStrokeOverlap } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// Both read off the verifications board rather than the scale; no token carries either.
const TILE_SIZE = 36;
const TILE_RADIUS = 10;
const TILE_ICON_SIZE = 18;

type Props = {
  product: UseSmileIDSampleProduct;
  jobId: string;
  time: string;
  status: UseSmileIDSampleStatus;
  onPress?: () => void;
  testID?: string;
  statusTestID?: string;
  style?: StyleProp<ViewStyle>;
};

/// One verification: a product tile, its name, a secondary line of job id and time, and the status badge.
export const UseSmileIDSampleJobRow = ({
  product,
  jobId,
  time,
  status,
  onPress,
  testID,
  statusTestID = UseSmileIDSampleTestIds.JOB_ROW_STATUS,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  // Inline at the design's scale; enlarged type lets the badge drop rather than squeezing the title.
  const stacks = PixelRatio.getFontScale() > 1;
  const Container = onPress ? Pressable : View;

  return (
    <Container
      testID={testID}
      {...(onPress ? { accessibilityRole: 'button' as const, onPress } : {})}
      style={[
        styles.card,
        {
          borderRadius: theme.shapes.card,
          backgroundColor: theme.colors.card.background,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
        },
        style,
      ]}
    >
      <View
        style={[
          stacks ? styles.stacked : styles.inline,
          smileStrokeOverlap,
          {
            minHeight: theme.dimens.space[64],
            padding: theme.dimens.spacing.sm,
            columnGap: theme.dimens.spacing.sm,
            rowGap: theme.dimens.spacing.xs,
          },
        ]}
      >
        <JobRowTile product={product} />
        <JobRowText product={product} jobId={jobId} time={time} stacks={stacks} />
        <UseSmileIDSampleStatusBadge status={status} testID={statusTestID} />
      </View>
    </Container>
  );
};

const JobRowTile = ({ product }: { product: UseSmileIDSampleProduct }) => {
  const hue = smileIDSampleProductHue(product);
  return (
    <View
      style={[
        styles.tile,
        { width: TILE_SIZE, height: TILE_SIZE, borderRadius: TILE_RADIUS, backgroundColor: hue.tile },
      ]}
    >
      <UseSmileIDSampleIcon
        name={smileIDSampleProductIcon(product)}
        tint={hue.icon}
        size={TILE_ICON_SIZE}
      />
    </View>
  );
};

const JobRowText = ({
  product,
  jobId,
  time,
  stacks,
}: {
  product: UseSmileIDSampleProduct;
  jobId: string;
  time: string;
  stacks: boolean;
}) => {
  const theme = useSmileIDSampleTheme();
  // One line at the design's scale; enlarged type wraps, because eliding it would clip.
  const lines = stacks ? undefined : 1;
  return (
    <View style={[stacks ? null : styles.text, { rowGap: theme.dimens.spacing.xxs }]}>
      <Text
        numberOfLines={lines}
        style={[theme.type.textStyleBodyStrong, { color: theme.colors.card.title }]}
      >
        {product.label}
      </Text>
      <Text
        numberOfLines={lines}
        style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}
      >
        {`${jobId} · ${time}`}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: { overflow: 'hidden', width: '100%' },
  inline: { alignItems: 'center', flexDirection: 'row' },
  stacked: { alignItems: 'center', flexDirection: 'row', flexWrap: 'wrap' },
  text: { flex: 1 },
  tile: { alignItems: 'center', justifyContent: 'center' },
});
