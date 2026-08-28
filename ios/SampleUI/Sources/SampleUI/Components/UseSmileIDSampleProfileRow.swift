import SwiftUI

/// An organisation and a supporting line. The hue varies per profile, so the caller passes it.
public struct UseSmileIDSampleProfileRow<Trailing: View>: View {
  private let organisation: String
  private let supportingText: String
  private let initials: String
  private let selected: Bool
  private let avatarColor: Color
  private let testId: String?
  private let onTap: () -> Void
  private let trailing: Trailing

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    organisation: String,
    supportingText: String,
    initials: String,
    selected: Bool,
    // The avatar's own default: a second one drew one profile in two colours.
    avatarColor: Color = smileProfileHues[0],
    testId: String? = nil,
    onTap: @escaping () -> Void,
    @ViewBuilder trailing: () -> Trailing = { EmptyView() }
  ) {
    self.organisation = organisation
    self.supportingText = supportingText
    self.initials = initials
    self.selected = selected
    self.avatarColor = avatarColor
    self.testId = testId
    self.onTap = onTap
    self.trailing = trailing()
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingSm) {
        UseSmileIDSampleAvatar(initials: initials, containerColor: avatarColor)
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          UseSmileIDSampleText(
            organisation,
            style: UseSmileIDSampleTheme.type.textStyleBodyStrong.with(size: 14.5)
          )
          .foregroundColor(colors.textTitle)
          UseSmileIDSampleText(supportingText, style: UseSmileIDSampleTheme.type.textStyleCaption)
            .foregroundColor(colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if Trailing.self != EmptyView.self {
          trailing
        } else if selected {
          UseSmileIDSampleIcon(SmileIcons.check, tint: colors.primary, size: SmileSpacing.sizeIconMd)
        }
      }
      .padding(.horizontal, Self.paddingX)
      .padding(.vertical, SmileSpacing.spacingSm)
      .frame(minHeight: minHeight)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .fill(selected ? colors.surfaceTile : colors.surface)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
      )
    }
    .buttonStyle(.plain)
    // A picker row, not a button: VoiceOver should say which profile is chosen.
    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    .useSmileIDSampleTestId(testId)
  }

  private static var paddingX: CGFloat {
    14
  }
}
