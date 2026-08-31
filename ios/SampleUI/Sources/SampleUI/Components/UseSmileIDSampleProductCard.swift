import SwiftUI

/// A product tile: a gradient in the product's hue, a hairline stroke, its icon as a watermark.
public struct UseSmileIDSampleProductCard<Ghost: View>: View {
  private let title: String
  private let family: String
  private let hue: SmileProductHue
  private let icon: SmileIcon
  private let enabled: Bool
  private let testId: String?
  private let action: () -> Void
  private let ghost: (Color) -> Ghost

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64 * 2 + SmileSpacing.space20
  @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(
    title: String,
    family: String,
    hue: SmileProductHue,
    icon: SmileIcon,
    enabled: Bool = true,
    testId: String? = nil,
    action: @escaping () -> Void,
    @ViewBuilder ghost: @escaping (Color) -> Ghost = { _ in EmptyView() }
  ) {
    self.title = title
    self.family = family
    self.hue = hue
    self.icon = icon
    self.enabled = enabled
    self.testId = testId
    self.action = action
    self.ghost = ghost
  }

  public var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingLg) {
        UseSmileIDSampleIcon(icon, tint: hue.cardIcon, size: SmileSpacing.sizeIconMd)
          .frame(width: tileSize, height: tileSize)
          .background(
            RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.tile, style: .continuous)
              .fill(enabled ? SmileColorLight.colorSurface : colors.surface)
          )
        HStack(alignment: .bottom) {
          label
          Spacer(minLength: SmileSpacing.spacingXs)
          go
        }
      }
      .padding(SmileSpacing.spacingMd)
      .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
      .background(fill)
      .overlay(alignment: .topTrailing) {
        // The ink goes IN, because the mark colours itself and would ignore a foreground style.
        ghost(ghostInk.opacity(Self.ghostAlpha))
          .offset(x: SmileSpacing.spacingMd, y: -SmileSpacing.spacingXs)
      }
      .clipShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
      )
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .useSmileIDSampleTestId(testId)
  }

  /// One text node with two runs, not two stacked `Text`s, which drift apart at large sizes. The
  /// title shrinks to fit its column before it is allowed to wrap, and only at the default size.
  private var label: some View {
    let type = UseSmileIDSampleTheme.type
    let titleStyle = type.textStyleBodyStrong
    let familyStyle = type.textStyleCaption
    let ink = enabled ? SmileColorLight.colorTextInverse : colors.textMuted
    return (
      Text(title + "\n")
        .font(UseSmileIDSampleFonts.font(titleStyle))
        + Text(family)
        .font(UseSmileIDSampleFonts.font(familyStyle.with(size: familyStyle.size)))
    )
    .tracking(smileCardTitleTracking)
    .foregroundColor(ink)
    .lineLimit(sizeCategory.isAccessibilityCategory ? nil : 2)
    .minimumScaleFactor(Self.labelFloor / titleStyle.size)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// The design runs the outer stop past the card's edge, and a gradient stop must land inside
  /// 0...1 — so the last stop is the colour the gradient has reached by the edge.
  private var fill: LinearGradient {
    guard enabled else {
      return LinearGradient(colors: [colors.surfaceMuted, colors.surfaceMuted], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    return LinearGradient(
      stops: [
        .init(color: hue.from.opacity(hue.fromAlpha), location: hue.stopStart),
        .init(color: gradientEnd, location: min(hue.stopEnd, 1))
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var gradientEnd: Color {
    let start = hue.from.opacity(hue.fromAlpha)
    let end = hue.to.opacity(hue.toAlpha)
    guard hue.stopEnd > 1 else { return end }
    return start.mixed(with: end, by: (1 - hue.stopStart) / (hue.stopEnd - hue.stopStart))
  }

  /// Each mark takes the ink for the end of the gradient it covers: one fixed value leaves the go
  /// pill invisible on the darkest card and the ghost invisible on the lightest.
  private var ghostInk: Color {
    hue.from.inkOn
  }

  private var go: some View {
    UseSmileIDSampleIcon(
      SmileIcons.arrowForward,
      tint: enabled ? SmileColorLight.colorTextInverse : colors.textMuted,
      size: SmileSpacing.sizeIconSm
    )
    .frame(width: SmileSpacing.sizeIconLg, height: SmileSpacing.sizeIconLg)
    .background(Circle().fill((enabled ? gradientEnd.inkOn : colors.textMuted).opacity(Self.scrimAlpha)))
  }

  private static var scrimAlpha: Double {
    0.16
  }

  private static var ghostAlpha: Double {
    0.10
  }

  private static var labelFloor: CGFloat {
    13
  }
}
