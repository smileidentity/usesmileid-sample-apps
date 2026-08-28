import SwiftUI

/// Initials in a rounded square, or a placeholder without them.
///
/// A rounded square at radius 12, not a circle (node 5206:2904). The size scales with Dynamic
/// Type, because a box that stays fixed while its initials grow renders an ellipse at the largest
/// sizes.
public struct UseSmileIDSampleAvatar: View {
  private let initials: String
  private let containerColor: Color
  private let testId: String?

  @ScaledMetric(relativeTo: .body) private var size: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    initials: String,
    containerColor: Color = smileProfileHues[0],
    testId: String? = nil
  ) {
    self.initials = initials
    self.containerColor = containerColor
    self.testId = testId
  }

  public var body: some View {
    let hasInitials = !initials.trimmingCharacters(in: .whitespaces).isEmpty
    return UseSmileIDSampleText(
      hasInitials ? initials : "?",
      style: UseSmileIDSampleTheme.type.avatarFont
    )
    .foregroundColor(hasInitials ? colors.avatar.text : colors.avatar.placeholderIcon)
    .multilineTextAlignment(.center)
    .frame(width: size, height: size)
    .background(
      RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        .fill(hasInitials ? containerColor : colors.avatar.placeholderBackground)
    )
    .useSmileIDSampleTestId(testId)
  }

  private static let radius: CGFloat = 12
}

/// The avatar fill for a profile at `index`, cycled.
///
/// Position, not a hash of the initials: a hash reproduces no design order and gives the same
/// profile a different colour on each platform.
public func useSmileIDSampleAvatarColor(profileIndex: Int) -> Color {
  smileProfileHues[max(0, profileIndex) % smileProfileHues.count]
}
