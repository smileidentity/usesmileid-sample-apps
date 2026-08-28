// Smile ID Design System — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the upstream SwiftUI emitter omits the type ramp entirely — not even the comments the
// Compose emitter leaves. Names mirror the Dart and Compose emitters' SmileType so the platforms
// stay diffable. Delete this file once upstream emits the styles.
//
// This is DATA, not a Font: a custom face is addressed by PostScript name, which the weight number
// resolves to in the app's typography layer.

import CoreGraphics

/// One style from the token source's ramp.
public struct SmileTextStyle: Equatable, Sendable {
  /// The token's own family name, resolved to a bundled face by the app's typography layer.
  public let family: String
  /// The DTCG numeric weight (400–800), not a `Font.Weight`.
  public let weight: Int
  public let size: CGFloat
  public let lineHeight: CGFloat
  public let tracking: CGFloat

  public init(family: String, weight: Int, size: CGFloat, lineHeight: CGFloat, tracking: CGFloat) {
    self.family = family
    self.weight = weight
    self.size = size
    self.lineHeight = lineHeight
    self.tracking = tracking
  }

  /// SwiftUI's `lineSpacing` is the gap BETWEEN lines, where the token carries the total height.
  public var lineSpacing: CGFloat {
    max(0, lineHeight - size)
  }
}

/// The token source's type ramp, bound to the font families the app supplies.
public struct SmileTypeStyles: Sendable {
  private let display: String
  private let body: String

  public init(display: String, body: String) {
    self.display = display
    self.body = body
  }

  public var textStyleDisplayLg: SmileTextStyle {
    SmileTextStyle(
      family: display,
      weight: 800,
      size: 40,
      lineHeight: 48,
      tracking: -0.4
    )
  }

  public var textStyleDisplayMd: SmileTextStyle {
    SmileTextStyle(
      family: display,
      weight: 800,
      size: 32,
      lineHeight: 40,
      tracking: -0.4
    )
  }

  public var textStyleHeadingPage: SmileTextStyle {
    SmileTextStyle(
      family: display,
      weight: 800,
      size: 24,
      lineHeight: 32,
      tracking: -0.4
    )
  }

  public var textStyleHeadingCard: SmileTextStyle {
    SmileTextStyle(
      family: display,
      weight: 800,
      size: 20,
      lineHeight: 26,
      tracking: -0.4
    )
  }

  public var textStyleHeadingSection: SmileTextStyle {
    SmileTextStyle(
      family: display,
      weight: 600,
      size: 18,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var textStyleTitle: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 16,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var textStyleSubtitle: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 500,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var textStyleBody: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 16,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var textStyleBodyStrong: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 600,
      size: 16,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var textStyleBodySm: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var textStyleCaption: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 500,
      size: 12,
      lineHeight: 16,
      tracking: 0
    )
  }

  public var textStyleOverline: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 10,
      lineHeight: 16,
      tracking: 0
    )
  }

  public var textStyleButton: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 16,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var textStyleButtonSm: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var avatarFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 500,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var badgeFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 10,
      lineHeight: 16,
      tracking: 0
    )
  }

  public var bannerTitleFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 600,
      size: 16,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var bannerTextFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var buttonFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 16,
      lineHeight: 24,
      tracking: 0
    )
  }

  public var cardTitleFont: SmileTextStyle {
    SmileTextStyle(
      family: display,
      weight: 800,
      size: 20,
      lineHeight: 26,
      tracking: -0.4
    )
  }

  public var dataFieldLabelFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 500,
      size: 12,
      lineHeight: 16,
      tracking: 0
    )
  }

  public var dataFieldValueFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var filterChipFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var inputFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var linkFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var searchFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var tableHeaderFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 700,
      size: 10,
      lineHeight: 16,
      tracking: 0
    )
  }

  public var tableCellFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 400,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }

  public var tabFont: SmileTextStyle {
    SmileTextStyle(
      family: body,
      weight: 500,
      size: 14,
      lineHeight: 20,
      tracking: 0
    )
  }
}
