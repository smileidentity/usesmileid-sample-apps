import SwiftUI

/// The active session and its countdown; `remaining` arrives formatted, the deadline being absolute.
public struct UseSmileIDSampleSessionCard: View {
  private let sessionId: String
  private let remaining: String

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(sessionId: String, remaining: String) {
    self.sessionId = sessionId
    self.remaining = remaining
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
        UseSmileIDSampleText(
          "ACTIVE TOKEN SESSION",
          style: UseSmileIDSampleTheme.type.textStyleOverline.with(tracking: smileLabelTracking)
        )
        UseSmileIDSampleText("Linked to session \(sessionId)", style: UseSmileIDSampleTheme.type.textStyleCaption)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      // The one value that must stay whole, so the text beside it yields instead.
      UseSmileIDSampleText(remaining, style: UseSmileIDSampleTheme.type.textStyleHeadingCard.with(size: 20))
        .fixedSize()
        .useSmileIDSampleTestId(UseSmileIDSampleTestIds.sessionCountdown)
    }
    // The gradient is scheme-independent, so its ink is too.
    .foregroundColor(SmileColorLight.colorTextInverse)
    .padding(SmileSpacing.spacingMd)
    .frame(minHeight: minHeight)
    .background(
      LinearGradient(
        colors: zip(smileTokenSessionGradient, smileTokenSessionGradientAlpha).map { $0.opacity($1) },
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
    // A container that contains, or the card's id replaces the countdown's and a flow cannot read it.
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.sessionCard)
  }
}

/// Replaces ``UseSmileIDSampleSessionCard`` on expiry: a neutral card, not a warning-accented one.
public struct UseSmileIDSampleSessionEndedBanner: View {
  private let onScan: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(onScan: @escaping () -> Void) {
    self.onScan = onScan
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
        UseSmileIDSampleText("TOKEN SESSION ENDED", style: UseSmileIDSampleTheme.type.textStyleOverline)
          .foregroundColor(colors.banner.text)
        UseSmileIDSampleText("Scan a token to relink", style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
          .foregroundColor(colors.banner.title)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      // A text action widened to the touch target, per the component's spec — not a filled pill.
      Button(action: onScan) {
        UseSmileIDSampleText("Scan", style: UseSmileIDSampleTheme.type.linkFont)
          .foregroundColor(colors.primary)
          .fixedSize()
          .padding(.horizontal, SmileSpacing.spacingXs)
          .frame(minHeight: SmileSpacing.sizeControlMd)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(SmileSpacing.spacingMd)
    .frame(minHeight: minHeight)
    // Surface-muted per this component's token list; the banner contract's fill is a warm sand.
    .background(colors.surfaceMuted)
    .clipShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.sessionEndedBanner)
  }
}
