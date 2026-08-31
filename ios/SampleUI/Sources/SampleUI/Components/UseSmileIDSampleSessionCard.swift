import SwiftUI

/// The active token session and its countdown. `remaining` arrives formatted, because the deadline
/// is absolute and the ticking is the screen's.
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
      Button(action: onScan) {
        UseSmileIDSampleText("Scan", style: UseSmileIDSampleTheme.type.textStyleButtonSm)
          .foregroundColor(colors.onPrimary)
          .padding(.horizontal, SmileSpacing.spacingMd)
          .padding(.vertical, SmileSpacing.spacingXs)
          .frame(minHeight: SmileSpacing.space40)
          .background(Capsule().fill(colors.primary))
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
