// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → deltas, not the design system. Everything the
// design system carries no role for lives here; delete each value once upstream carries its role.
// The Compose twin is SmileProductHues.kt and the two are generated from the same entries.

import SwiftUI

/// One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair.
public struct SmileProductHue: Equatable, Sendable {
  public let from: Color
  public let to: Color
  public let cardIcon: Color
  public let icon: Color
  public let tile: Color
  /// Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge.
  public let stopStart: CGFloat
  public let stopEnd: CGFloat
  public let fromAlpha: CGFloat
  public let toAlpha: CGFloat
}

/// One status pill's soft fill: a pale background with text that clears contrast on it.
public struct SmileSoftBadgeFill: Equatable, Sendable {
  public let background: Color
  public let text: Color
}

/// Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet.
public let smileProductHues: [String: SmileProductHue] = [
  "smartSelfieEnrollment": SmileProductHue(
    from: Color(hex: 0xffb53d),
    to: Color(hex: 0xa78bfa),
    cardIcon: Color(hex: 0x05723a),
    icon: Color(hex: 0x05723a),
    tile: Color(hex: 0xe4f2ea),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79
  ),
  "smartSelfieAuth": SmileProductHue(
    from: Color(hex: 0x3a49b4),
    to: Color(hex: 0x5361d6),
    cardIcon: Color(hex: 0x3a49b4),
    icon: Color(hex: 0x3a49b4),
    tile: Color(hex: 0xe9ebfa),
    stopStart: 0.06451,
    stopEnd: 0.91913,
    fromAlpha: 1.0,
    toAlpha: 1.0
  ),
  "documentVerification": SmileProductHue(
    from: Color(hex: 0x2cc05c),
    to: Color(hex: 0x00aa99),
    cardIcon: Color(hex: 0x06a850),
    icon: Color(hex: 0xb36500),
    tile: Color(hex: 0xfbeeda),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79
  ),
  "enhancedDocumentVerification": SmileProductHue(
    from: Color(hex: 0x04713a),
    to: Color(hex: 0x00aa99),
    cardIcon: Color(hex: 0x04713a),
    icon: Color(hex: 0x2d2b2a),
    tile: Color(hex: 0xedebea),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 1.0,
    toAlpha: 0.79
  ),
  "biometricKyc": SmileProductHue(
    from: Color(hex: 0x151f72),
    to: Color(hex: 0x2b3a9e),
    cardIcon: Color(hex: 0x151f72),
    icon: Color(hex: 0x151f72),
    tile: Color(hex: 0xe5edff),
    stopStart: 0.56022,
    stopEnd: 1.1051,
    fromAlpha: 1.0,
    toAlpha: 1.0
  ),
  "enhancedKyc": SmileProductHue(
    from: Color(hex: 0x0ea5e9),
    to: Color(hex: 0x151f72),
    cardIcon: Color(hex: 0x0ea5e9),
    icon: Color(hex: 0x05726e),
    tile: Color(hex: 0xe4f1f0),
    stopStart: 0.66627,
    stopEnd: 1.2978,
    fromAlpha: 0.79,
    toAlpha: 1.0
  )
]

/// Keyed by feedback role. The design system's own badge.* pairs are saturated, a different treatment.
public let smileSoftBadgeFills: [String: SmileSoftBadgeFill] = [
  "success": SmileSoftBadgeFill(
    background: Color(hex: 0xdbf5e4),
    text: Color(hex: 0x04713a)
  ),
  "info": SmileSoftBadgeFill(
    background: Color(hex: 0xe5edff),
    text: Color(hex: 0x151f72)
  ),
  "warning": SmileSoftBadgeFill(
    background: Color(hex: 0xfff0d9),
    text: Color(hex: 0x7a4a00)
  ),
  "error": SmileSoftBadgeFill(
    background: Color(hex: 0xfde4e1),
    text: Color(hex: 0xa11209)
  )
]

/// The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw.
public let smileBorderStrong: Color = .init(hex: 0xc2c5cb)

/// The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream.
public let smileSurface2: Color = .init(hex: 0xeaecf0)

/// The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta.
public let smileOffBlackLight: Color = .init(hex: 0x2d2b2a)
public let smileOffBlackDark: Color = .init(hex: 0xf9f0e7)
/// The floating nav bar's fill — see the `navBarFill` delta.
public let smileNavBarLight: Color = .init(hex: 0xffffff)
public let smileNavBarDark: Color = .init(hex: 0x21232c)

/// Avatar fills, one per profile, taken in list order and cycled beyond the list.
public let smileProfileHues: [Color] = [
  Color(hex: 0x151f72),
  Color(hex: 0x05723a),
  Color(hex: 0xb36500),
  Color(hex: 0x2d2b2a)
]

/// The session card's horizontal gradient. Both stops are translucent, so the card composites against the page.
public let smileTokenSessionGradient: [Color] = [Color(hex: 0x0c41b2), Color(hex: 0xa78bfa)]
public let smileTokenSessionGradientAlpha: [CGFloat] = [0.78, 0.79]

/// The countdown ring: this colour solid for progress, and the same colour faded for the track.
public let smileTokenRing: Color = .init(hex: 0x06a850)
public let smileTokenRingTrackOpacity: CGFloat = 0.18
/// The design's Type/Label: a point larger than text-style.overline, and spaced.
public let smileLabelSize: CGFloat = 11
public let smileLabelTracking: CGFloat = 0.88
/// The card's two label runs, each one property off a token — see the `cardLabelRuns` delta.
public let smileCardTitleTracking: CGFloat = -0.4
public let smileCardFamilyWeight: Int = 400
/// One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta.
public let smileCardStrokeLight: Color = .init(hex: 0xeaecf0)
public let smileCardStrokeDark: Color = .init(hex: 0x2d3748)
public let smileCardStrokeWidth: CGFloat = 0.5
/// The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta.
public let smileHeadingPageSize: CGFloat = 26
public let smileHeadingPageLineHeight: CGFloat = 31.2
public let smileHeadingPageTracking: CGFloat = -0.26
public let smileHeadingPageWeight: Int = 700
public let smileSectionHeaderSize: CGFloat = 15
public let smileSectionHeaderLineHeight: CGFloat = 19.5
public let smileSectionHeaderWeight: Int = 700
