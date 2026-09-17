// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → deltas, not the design system. Everything the
// design system carries no role for lives here; delete each value once upstream carries its role.

/** One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair. */
export type SmileProductHue = {
  readonly from: string;
  readonly to: string;
  readonly cardIcon: string;
  readonly icon: string;
  readonly tile: string;
  /** Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge. */
  readonly stopStart: number;
  readonly stopEnd: number;
  readonly fromAlpha: number;
  readonly toAlpha: number;
};

/** Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet. */
export const smileProductHues: Readonly<Record<string, SmileProductHue>> = {
  smartSelfieEnrollment: {
    from: '#ffb53d',
    to: '#a78bfa',
    cardIcon: '#05723a',
    icon: '#05723a',
    tile: '#e4f2ea',
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79,
  },
  smartSelfieAuth: {
    from: '#3a49b4',
    to: '#5361d6',
    cardIcon: '#3a49b4',
    icon: '#3a49b4',
    tile: '#e9ebfa',
    stopStart: 0.06451,
    stopEnd: 0.91913,
    fromAlpha: 1.0,
    toAlpha: 1.0,
  },
  documentVerification: {
    from: '#2cc05c',
    to: '#00aa99',
    cardIcon: '#06a850',
    icon: '#b36500',
    tile: '#fbeeda',
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79,
  },
  enhancedDocumentVerification: {
    from: '#04713a',
    to: '#00aa99',
    cardIcon: '#04713a',
    icon: '#2d2b2a',
    tile: '#edebea',
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79,
  },
  biometricKyc: {
    from: '#151f72',
    to: '#2b3a9e',
    cardIcon: '#151f72',
    icon: '#151f72',
    tile: '#e5edff',
    stopStart: 0.56022,
    stopEnd: 1.1051,
    fromAlpha: 1.0,
    toAlpha: 1.0,
  },
  enhancedKyc: {
    from: '#0ea5e9',
    to: '#151f72',
    cardIcon: '#0ea5e9',
    icon: '#05726e',
    tile: '#e4f1f0',
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 0.79,
    toAlpha: 1.0,
  },
};

/** One status pill's soft fill: a pale background with text that clears contrast on it. */
export type SmileSoftBadgeFill = { readonly background: string; readonly text: string };

/** Keyed by feedback role. The design system's own badge.* pairs are saturated, which is a different treatment. */
export const smileSoftBadgeFills: Readonly<Record<string, SmileSoftBadgeFill>> = {
  success: {
    background: '#dbf5e4',
    text: '#04713a',
  },
  info: {
    background: '#e5edff',
    text: '#151f72',
  },
  warning: {
    background: '#fff0d9',
    text: '#7a4a00',
  },
  error: {
    background: '#fde4e1',
    text: '#a11209',
  },
};

/** The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw. */
export const smileBorderStrong = '#c2c5cb';

/** The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream. */
export const smileSurface2 = '#eaecf0';

/** The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta. */
export const smileOffBlackLight = '#2d2b2a';
export const smileOffBlackDark = '#f9f0e7';
/** The floating nav bar's fill — see the `navBarFill` delta. */
export const smileNavBarLight = '#ffffff';
export const smileNavBarDark = '#21232c';

/** Avatar fills, one per profile, taken in list order and cycled beyond the list. */
export const smileProfileHues: readonly string[] = [
  '#151f72',
  '#05723a',
  '#b36500',
  '#2d2b2a',
];

/** The session card's horizontal gradient. Both stops are translucent, so the card composites against the page. */
export const smileTokenSessionGradient: readonly [string, string] = ['#0c41b2', '#a78bfa'];
export const smileTokenSessionGradientAlpha: readonly [number, number] = [0.78, 0.79];

/** The countdown ring: this colour solid for progress, and the same colour faded for the track. */
export const smileTokenRing = '#06a850';
export const smileTokenRingTrackOpacity = 0.18;
/** The design's Type/Label: a point larger than text-style.overline, and spaced. */
export const smileLabelSize = 11;
export const smileLabelTracking = 0.88;
/** The card's two label runs, each one property off a token — see the `cardLabelRuns` delta. */
export const smileCardTitleTracking = -0.4;
export const smileCardFamilyWeight = 400;
/** One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta. */
export const smileCardStrokeLight = '#eaecf0';
export const smileCardStrokeDark = '#2d3748';
export const smileCardStrokeWidth = 0.5;
/** The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta. */
export const smileHeadingPageSize = 26;
export const smileHeadingPageLineHeight = 31.2;
export const smileHeadingPageTracking = -0.26;
export const smileHeadingPageWeight = 700;
export const smileSectionHeaderSize = 15;
export const smileSectionHeaderLineHeight = 19.5;
export const smileSectionHeaderWeight = 700;
