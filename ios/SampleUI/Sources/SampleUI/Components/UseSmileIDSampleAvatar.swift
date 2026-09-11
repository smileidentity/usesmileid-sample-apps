import SwiftUI

/// Initials in a rounded square at radius 12, not a circle; the box scales with Dynamic Type or its initials render an ellipse.
public struct UseSmileIDSampleAvatar: View {
  private let initials: String
  private let containerColor: Color
  private let testId: String?

  @ScaledMetric private var size: CGFloat
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    initials: String,
    size: CGFloat = SmileSpacing.space40,
    containerColor: Color = smileProfileHues[0],
    testId: String? = nil
  ) {
    self.initials = initials
    _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
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

/// The avatar fill for a profile at `index`, cycled by position: a hash of the initials would differ per platform.
public func useSmileIDSampleAvatarColor(profileIndex: Int) -> Color {
  smileProfileHues[max(0, profileIndex) % smileProfileHues.count]
}
