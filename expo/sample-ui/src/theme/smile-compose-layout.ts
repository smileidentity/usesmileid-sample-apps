import type { ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import type { UseSmileIDSampleTheme } from './use-smile-id-sample-theme';

/// The padding that keeps content where Compose puts it, since Compose draws a border over its padding and React Native sits it inside the box.
export const insetForBorder = (padding: number, borderWidth: number): number => padding - borderWidth;

/// Pulls a card's content over its stroke, the same correction for a card whose padding lives on a child.
export const smileStrokeOverlap: ViewStyle = { margin: -smileCardStrokeWidth };

/// Lays a control out at the platform's minimum target, as Compose's `minimumInteractiveComponentSize` does; `height` for a full-width row.
export const touchTargetStyle = (theme: UseSmileIDSampleTheme, axes: 'both' | 'height' = 'both'): ViewStyle =>
  axes === 'height'
    ? { minHeight: theme.dimens.touchTarget }
    : { minHeight: theme.dimens.touchTarget, minWidth: theme.dimens.touchTarget };
