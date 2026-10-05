import { Pressable, ScrollView, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleAvatar } from '../components/use-smile-id-sample-avatar';
import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleProductCard } from '../components/use-smile-id-sample-product-card';
import { UseSmileIDSampleProductGrid } from '../components/use-smile-id-sample-product-grid';
import { UseSmileIDSampleSectionHeader } from '../components/use-smile-id-sample-section-header';
import { UseSmileIDSampleSessionCard } from '../components/use-smile-id-sample-session-card';
import { UseSmileIDSampleResultLine } from '../components/use-smile-id-sample-result-card';
import { UseSmileIDSampleSessionEndedBanner } from '../components/use-smile-id-sample-session-ended-banner';
import type { UseSmileIDSampleResult } from '../model/use-smile-id-sample-result';
import {
  smileIDSampleProductHue,
  smileIDSampleProductIcon,
  UseSmileIDSampleProductSection,
  smileIDSampleProductCardFamily,
  smileIDSampleProductCardTitle,
  smileIDSampleProductSectionLabel,
  smileIDSampleProductsOf,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleProductSectionKey,
} from '../model/use-smile-id-sample-product';
import {
  smileHeadingPageLineHeight,
  smileHeadingPageSize,
  smileHeadingPageTracking,
  smileHeadingPageWeight,
  smileProfileHues,
} from '../smile-product-hues';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';
import { touchTargetStyle } from '../theme/smile-compose-layout';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// The design draws the ghost watermark bleeding off the corner at this size.
const GHOST_SIZE = 69;

/// What the products header and session strip render, so the screen stays free of clock and store.
export type UseSmileIDSampleProductsState = {
  readonly initials: string;
  /// The active profile's avatar hue, so every screen showing it agrees.
  readonly avatarColor?: string;
  readonly sessionId?: string | null;
  readonly sessionRemaining?: string | null;
  readonly sessionEnded?: boolean;
  /// The last run's result; its compact line shows only while that run is in flight.
  readonly result?: UseSmileIDSampleResult | null;
};

type Props = {
  state: UseSmileIDSampleProductsState;
  onProductPress: (product: UseSmileIDSampleProduct) => void;
  onProfilePress: () => void;
  onScanPress: () => void;
  /// Whatever draws over the list, which the floating nav bar does.
  bottomInset?: number;
  style?: StyleProp<ViewStyle>;
};

/// The products grid, the entry point every flow starts from.
export const ProductsScreen = ({
  state,
  onProductPress,
  onProfilePress,
  onScanPress,
  bottomInset = 0,
  style,
}: Props) => {
  const strings = useSmileIDSampleStrings();
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const sections = Object.keys(UseSmileIDSampleProductSection) as UseSmileIDSampleProductSectionKey[];

  return (
    <ScrollView
      testID={UseSmileIDSampleTestIds.PRODUCTS_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }, style]}
      contentContainerStyle={{
        paddingTop: insets.top,
        paddingBottom: bottomInset,
        rowGap: theme.dimens.spacing.sm,
      }}
    >
      <View style={{ paddingHorizontal: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.xxs }}>
        <View style={[styles.header, { columnGap: theme.dimens.spacing.xs }]}>
          <Text
            style={[
              atSize(
                atWeight(theme.type.textStyleHeadingPage, smileHeadingPageWeight),
                smileHeadingPageSize,
                smileHeadingPageLineHeight,
              ),
              styles.title,
              {
                letterSpacing: smileHeadingPageTracking,
                color: theme.colors.offBlack,
              },
            ]}
          >
            {strings.productsTitle}
          </Text>
          {/* The environment chip is hidden here by ruling; the result card publishes it instead. */}
          <Pressable
            testID={UseSmileIDSampleTestIds.PROFILE_AVATAR_BUTTON}
            accessibilityRole="button"
            accessibilityLabel={strings.productsSwitchProfile}
            onPress={onProfilePress}
            style={[styles.avatar, touchTargetStyle(theme)]}
          >
            <UseSmileIDSampleAvatar
              initials={state.initials}
              containerColor={state.avatarColor ?? smileProfileHues[0]}
            />
          </Pressable>
        </View>
        <Text style={[theme.type.textStyleCaption, { color: theme.colors.offBlack }]}>
          {strings.productsSubtitle}
        </Text>
      </View>

      {state.result?.jobStatus === 'running' ? (
        <UseSmileIDSampleResultLine result={state.result} style={{ marginHorizontal: theme.dimens.spacing.md }} />
      ) : null}

      {state.sessionEnded === true ? (
        <UseSmileIDSampleSessionEndedBanner
          onScan={onScanPress}
          style={{ marginHorizontal: theme.dimens.spacing.md }}
        />
      ) : state.sessionId != null && state.sessionRemaining != null ? (
        <UseSmileIDSampleSessionCard
          sessionId={state.sessionId}
          remaining={state.sessionRemaining}
          style={{ marginHorizontal: theme.dimens.spacing.md }}
        />
      ) : null}

      {sections.map((section) => {
        const products = smileIDSampleProductsOf(section);
        return (
          <View
            key={section}
            style={{ paddingHorizontal: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.xs }}
          >
            <UseSmileIDSampleSectionHeader text={smileIDSampleProductSectionLabel(section, strings)} />
            <UseSmileIDSampleProductGrid
              cells={products.map((product) => (
                <UseSmileIDSampleProductCard
                  key={product.id}
                  title={smileIDSampleProductCardTitle(product, strings)}
                  family={smileIDSampleProductCardFamily(product, strings)}
                  onPress={() => onProductPress(product)}
                  hue={smileIDSampleProductHue(product)}
                  testID={UseSmileIDSampleSuffixedTestIds.productCard(product.id)}
                  icon={(tint) => (
                    <UseSmileIDSampleIcon name={smileIDSampleProductIcon(product)} tint={tint} />
                  )}
                  ghost={(tint) => (
                    <UseSmileIDSampleIcon
                      name={smileIDSampleProductIcon(product)}
                      tint={tint}
                      size={GHOST_SIZE}
                    />
                  )}
                />
              ))}
            />
          </View>
        );
      })}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  header: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  title: { flex: 1 },
  avatar: { alignItems: 'center', justifyContent: 'center' },
});
