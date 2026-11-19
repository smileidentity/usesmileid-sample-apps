import SwiftUI

/// Which accent a banner carries: warning for a failure the user can act on, error for one that is final.
public enum UseSmileIDSampleBannerTone: Sendable {
  case warning
  case error
}

/// The design system's banner on the card surface: an accent bar and glyph, the message, and at most one action under it.
public struct UseSmileIDSampleBanner: View {
  private let message: String
  private let tone: UseSmileIDSampleBannerTone
  private let actionLabel: String?
  private let actionProminent: Bool
  private let testId: String?
  private let actionTestId: String?
  private let onAction: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    message: String,
    tone: UseSmileIDSampleBannerTone,
    actionLabel: String? = nil,
    actionProminent: Bool = true,
    testId: String? = nil,
    actionTestId: String? = nil,
    onAction: @escaping () -> Void = {}
  ) {
    self.message = message
    self.tone = tone
    self.actionLabel = actionLabel
    self.actionProminent = actionProminent
    self.testId = testId
    self.actionTestId = actionTestId
    self.onAction = onAction
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingMd) {
      HStack(alignment: .top, spacing: SmileSpacing.spacingSm) {
        UseSmileIDSampleIcon(glyph, tint: accent)
        UseSmileIDSampleText(message, style: UseSmileIDSampleTheme.type.textStyleBody)
          .foregroundColor(colors.banner.title)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
      }
      if let actionLabel, actionProminent {
        UseSmileIDSampleButton(text: actionLabel, testId: actionTestId, action: onAction)
      } else if let actionLabel {
        // Widened to the touch target, as the session-ended banner's text action is.
        Button(action: onAction) {
          UseSmileIDSampleText(actionLabel, style: UseSmileIDSampleTheme.type.linkFont)
            .foregroundColor(colors.primary)
            .fixedSize()
            .padding(.horizontal, SmileSpacing.spacingXs)
            .frame(minHeight: SmileSpacing.sizeControlMd)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .useSmileIDSampleTestId(actionTestId)
      }
    }
    .padding(SmileSpacing.spacingMd)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(alignment: .leading) {
      ZStack(alignment: .leading) {
        colors.card.background
        accent.frame(width: Self.accentWidth)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
    // Contain, or the banner's id replaces the action's in the accessibility tree.
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

  /// The banner contract's leading bar.
  private static let accentWidth: CGFloat = 4
}
