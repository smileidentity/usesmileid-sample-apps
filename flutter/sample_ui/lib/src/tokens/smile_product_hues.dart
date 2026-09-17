// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → deltas, not the design system. Everything the
// design system carries no role for lives here; delete each value once upstream carries its role.
//
// Metrics are bare doubles because Flutter measures in logical pixels — there is no dp or sp type
// for the emitter to name, and the Compose twin's `.dp`/`.sp` carry the same numbers.

import 'package:flutter/material.dart';

/// One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair.
@immutable
class SmileProductHue {
  const SmileProductHue({
    required this.from,
    required this.to,
    required this.cardIcon,
    required this.icon,
    required this.tile,
    required this.stopStart,
    required this.stopEnd,
    required this.fromAlpha,
    required this.toAlpha,
  });

  final Color from;
  final Color to;
  final Color cardIcon;
  final Color icon;
  final Color tile;

  /// Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge.
  final double stopStart;
  final double stopEnd;
  final double fromAlpha;
  final double toAlpha;
}

/// One status pill's soft fill: a pale background with text that clears contrast on it.
@immutable
class SmileSoftBadgeFill {
  const SmileSoftBadgeFill({required this.background, required this.text});

  final Color background;
  final Color text;
}

/// Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet.
const Map<String, SmileProductHue> smileProductHues = <String, SmileProductHue>{
  'smartSelfieEnrollment': SmileProductHue(
    from: Color(0xFFFFB53D),
    to: Color(0xFFA78BFA),
    cardIcon: Color(0xFF05723A),
    icon: Color(0xFF05723A),
    tile: Color(0xFFE4F2EA),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79,
  ),
  'smartSelfieAuth': SmileProductHue(
    from: Color(0xFF3A49B4),
    to: Color(0xFF5361D6),
    cardIcon: Color(0xFF3A49B4),
    icon: Color(0xFF3A49B4),
    tile: Color(0xFFE9EBFA),
    stopStart: 0.06451,
    stopEnd: 0.91913,
    fromAlpha: 1.0,
    toAlpha: 1.0,
  ),
  'documentVerification': SmileProductHue(
    from: Color(0xFF2CC05C),
    to: Color(0xFF00AA99),
    cardIcon: Color(0xFF06A850),
    icon: Color(0xFFB36500),
    tile: Color(0xFFFBEEDA),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79,
  ),
  'enhancedDocumentVerification': SmileProductHue(
    from: Color(0xFF04713A),
    to: Color(0xFF00AA99),
    cardIcon: Color(0xFF04713A),
    icon: Color(0xFF2D2B2A),
    tile: Color(0xFFEDEBEA),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79,
  ),
  'biometricKyc': SmileProductHue(
    from: Color(0xFF151F72),
    to: Color(0xFF2B3A9E),
    cardIcon: Color(0xFF151F72),
    icon: Color(0xFF151F72),
    tile: Color(0xFFE5EDFF),
    stopStart: 0.56022,
    stopEnd: 1.1051,
    fromAlpha: 1.0,
    toAlpha: 1.0,
  ),
  'enhancedKyc': SmileProductHue(
    from: Color(0xFF0EA5E9),
    to: Color(0xFF151F72),
    cardIcon: Color(0xFF0EA5E9),
    icon: Color(0xFF05726E),
    tile: Color(0xFFE4F1F0),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 0.79,
    toAlpha: 1.0,
  ),
};

/// Keyed by feedback role. The design system's own badge.* pairs are saturated, a different treatment.
const Map<String, SmileSoftBadgeFill> smileSoftBadgeFills =
    <String, SmileSoftBadgeFill>{
      'success': SmileSoftBadgeFill(
        background: Color(0xFFDBF5E4),
        text: Color(0xFF04713A),
      ),
      'info': SmileSoftBadgeFill(
        background: Color(0xFFE5EDFF),
        text: Color(0xFF151F72),
      ),
      'warning': SmileSoftBadgeFill(
        background: Color(0xFFFFF0D9),
        text: Color(0xFF7A4A00),
      ),
      'error': SmileSoftBadgeFill(
        background: Color(0xFFFDE4E1),
        text: Color(0xFFA11209),
      ),
    };

/// The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw.
const Color smileBorderStrong = Color(0xFFC2C5CB);

/// The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream.
const Color smileSurface2 = Color(0xFFEAECF0);

/// The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta.
const Color smileOffBlackLight = Color(0xFF2D2B2A);
const Color smileOffBlackDark = Color(0xFFF9F0E7);

/// The floating nav bar's fill — see the `navBarFill` delta.
const Color smileNavBarLight = Color(0xFFFFFFFF);
const Color smileNavBarDark = Color(0xFF21232C);

/// Avatar fills, one per profile, taken in list order and cycled beyond the list.
const List<Color> smileProfileHues = <Color>[
  Color(0xFF151F72),
  Color(0xFF05723A),
  Color(0xFFB36500),
  Color(0xFF2D2B2A),
];

/// The session card's horizontal gradient. Both stops are translucent, so the card composites against the page.
const List<Color> smileTokenSessionGradient = <Color>[
  Color(0xFF0C41B2),
  Color(0xFFA78BFA),
];
const List<double> smileTokenSessionGradientAlpha = <double>[0.78, 0.79];

/// The countdown ring: this colour solid for progress, and the same colour faded for the track.
const Color smileTokenRing = Color(0xFF06A850);
const double smileTokenRingTrackOpacity = 0.18;

/// The design's Type/Label: a point larger than text-style.overline, and spaced.
const double smileLabelSize = 11.0;
const double smileLabelTracking = 0.88;

/// The card's two label runs, each one property off a token — see the `cardLabelRuns` delta.
const double smileCardTitleTracking = -0.4;
const int smileCardFamilyWeight = 400;

/// One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta.
const Color smileCardStrokeLight = Color(0xFFEAECF0);
const Color smileCardStrokeDark = Color(0xFF2D3748);
const double smileCardStrokeWidth = 0.5;

/// The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta.
const double smileHeadingPageSize = 26.0;
const double smileHeadingPageLineHeight = 31.2;
const double smileHeadingPageTracking = -0.26;
const int smileHeadingPageWeight = 700;
const double smileSectionHeaderSize = 15.0;
const double smileSectionHeaderLineHeight = 19.5;
const int smileSectionHeaderWeight = 700;
