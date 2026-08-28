import SwiftUI

/// The design leads each trigger with an emoji rather than a glyph, so it carries no tint.
public struct UseSmileIDSampleTriggerEmoji: View {
  private let emoji: String

  public init(_ emoji: String) {
    self.emoji = emoji
  }

  public var body: some View {
    UseSmileIDSampleText(emoji, style: UseSmileIDSampleTheme.type.inputFont.with(size: 18))
  }
}

/// Looks like an input, behaves like a button.
///
/// Disabled is load-bearing: ID type stays greyed until a country is chosen.
public struct UseSmileIDSampleSelectTrigger<Leading: View>: View {
  private let value: String?
  private let placeholder: String
  private let enabled: Bool
  private let testId: String?
  private let onTap: () -> Void
  private let leading: Leading

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    value: String?,
    placeholder: String,
    enabled: Bool = true,
    testId: String? = nil,
    onTap: @escaping () -> Void,
    @ViewBuilder leading: () -> Leading = { EmptyView() }
  ) {
    self.value = value
    self.placeholder = placeholder
    self.enabled = enabled
    self.testId = testId
    self.onTap = onTap
    self.leading = leading()
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingXs) {
        if Leading.self != EmptyView.self {
          // A minimum, not a fixed size: the slot may hold an emoji, which grows with Dynamic Type.
          leading.frame(minWidth: SmileSpacing.sizeIconMd, minHeight: SmileSpacing.sizeIconMd)
        }
        UseSmileIDSampleText(
          value ?? placeholder,
          style: UseSmileIDSampleTheme.type.inputFont.with(size: 15)
        )
        .foregroundColor(contentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        UseSmileIDSampleIcon(SmileIcons.chevronDown, tint: contentColor, size: 12)
      }
      .padding(.horizontal, SmileSpacing.spacingMd)
      .padding(.vertical, SmileSpacing.spacingSm)
      .frame(minHeight: minHeight)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
          .fill(enabled ? colors.input.background : colors.button.disabledBackground)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
          .strokeBorder(
            enabled ? colors.primary : colors.input.border,
            lineWidth: SmileSpacing.borderWidthThin
          )
      )
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .useSmileIDSampleTestId(testId)
  }

  private var contentColor: Color {
    // The disabled pair, not textMuted on an almost-white surface, which does not read as disabled.
    if !enabled {
      return colors.button.disabledText
    }
    return value != nil ? colors.textTitle : colors.input.placeholder
  }
}
