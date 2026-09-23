import type { ViewStyle } from 'react-native';

import { smileCardStrokeWidth } from '../smile-product-hues';
import type { UseSmileIDSampleTheme } from './use-smile-id-sample-theme';

/// Compose draws a border over its padding and React Native inside it; this keeps content where Compose puts it.
export const insetForBorder = (padding: number, borderWidth: number): number => padding - borderWidth;

/// Pulls a card's content over its stroke, the same correction for a card whose padding lives on a child.
export const smileStrokeOverlap: ViewStyle = { margin: -smileCardStrokeWidth };

/// The platform's minimum target, as Compose's `minimumInteractiveComponentSize`; `height` for a full-width row.
export const touchTargetStyle = (theme: UseSmileIDSampleTheme, axes: 'both' | 'height' = 'both'): ViewStyle =>
  axes === 'height'
    ? { minHeight: theme.dimens.touchTarget }
    : { minHeight: theme.dimens.touchTarget, minWidth: theme.dimens.touchTarget };
