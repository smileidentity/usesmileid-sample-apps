import SwiftUI

/// Which failure a banner names: warning for one trying again later can get past, error for one it can't.
public enum UseSmileIDSampleBannerTone: Sendable {
  case warning
  case error
}

/// The app's neutral banner, as the session-ended card draws it: an all-caps caption over the message.
public struct UseSmileIDSampleBanner: View {
  private let caption: String
  private let message: String
  private let testId: String?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.locale) private var locale

  public init(caption: String, message: String, testId: String? = nil) {
    self.caption = caption
    self.message = message
    self.testId = testId
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleText(caption.uppercased(with: locale), style: UseSmileIDSampleTheme.type.textStyleOverline)
        .foregroundColor(colors.banner.text)
        .fixedSize(horizontal: false, vertical: true)
      UseSmileIDSampleText(message, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
        .foregroundColor(colors.banner.title)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(SmileSpacing.spacingMd)
    .frame(minHeight: minHeight)
    .background(colors.surfaceMuted)
    .clipShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
    // Contain, so the banner's id doesn't swallow its text in the accessibility tree.
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(testId)
  }
}
