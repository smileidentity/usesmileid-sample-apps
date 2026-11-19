import SwiftUI

/// Which accent a banner carries: warning for a failure trying again later can get past, error for one it can't.
public enum UseSmileIDSampleBannerTone: Sendable {
  case warning
  case error
}

/// The design system's banner: a neutral surface with the tone's accent edge and glyph, and a title over the message.
public struct UseSmileIDSampleBanner: View {
  private let title: String
  private let message: String
  private let tone: UseSmileIDSampleBannerTone
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    title: String,
    message: String,
    tone: UseSmileIDSampleBannerTone,
    testId: String? = nil
  ) {
    self.title = title
    self.message = message
    self.tone = tone
    self.testId = testId
  }

  public var body: some View {
    HStack(alignment: .top, spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleIcon(glyph, tint: accent)
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
        UseSmileIDSampleText(title, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
          .foregroundColor(colors.banner.title)
          .fixedSize(horizontal: false, vertical: true)
        UseSmileIDSampleText(message, style: UseSmileIDSampleTheme.type.textStyleBodySm)
          .foregroundColor(colors.banner.text)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(SmileSpacing.spacingMd)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(alignment: .leading) {
      ZStack(alignment: .leading) {
        colors.banner.background
        accent.frame(width: Self.accentWidth)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous))
    // The card stroke, as the session-ended banner takes: banner.border carries one light value in both schemes.
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
    // Contain, so the banner's id doesn't swallow its text in the accessibility tree.
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(testId)
  }

  private var accent: Color {
    switch tone {
    case .warning: colors.banner.warningAccent
    case .error: colors.banner.errorAccent
    }
  }

  private var glyph: SmileIcon {
    switch tone {
    case .warning: SmileIcons.warning
    case .error: SmileIcons.cancel
    }
  }

  /// The banner contract's leading edge.
  private static let accentWidth: CGFloat = 3
}
