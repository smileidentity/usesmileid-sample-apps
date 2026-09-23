import SwiftUI

/// The design leads each trigger with an emoji rather than a glyph, so it carries no tint.
public struct UseSmileIDSampleTriggerEmoji: View {
  private let emoji: String

  /// The label's line height, so the emoji's taller fallback line cannot push the trigger past 44.
  @ScaledMetric(relativeTo: .body) private var lineHeight: CGFloat = SmileSpacing.sizeIconMd

  public init(_ emoji: String) {
    self.emoji = emoji
  }

  public var body: some View {
    UseSmileIDSampleText(emoji, style: UseSmileIDSampleTheme.type.inputFont.with(size: 18))
      .frame(height: lineHeight)
  }
}

/// Looks like an input, behaves like a button. Disabled is load-bearing: ID type waits on a country.
public struct UseSmileIDSampleSelectTrigger<Leading: View>: View {
  private let value: String?
  private let placeholder: String
  private let enabled: Bool
  private let testId: String?
  private let onTap: () -> Void
  private let leading: (Color) -> Leading

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    value: String?,
    placeholder: String,
    enabled: Bool = true,
    testId: String? = nil,
    onTap: @escaping () -> Void,
    @ViewBuilder leading: @escaping (Color) -> Leading = { _ in EmptyView() }
  ) {
    self.value = value
    self.placeholder = placeholder
    self.enabled = enabled
    self.testId = testId
    self.onTap = onTap
    self.leading = leading
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingXs) {
        if Leading.self != EmptyView.self {
          // A minimum, not a fixed size: an emoji in the slot grows with Dynamic Type.
          leading(contentColor).frame(minWidth: SmileSpacing.sizeIconMd, minHeight: SmileSpacing.sizeIconMd)
        }
        UseSmileIDSampleText(
          value ?? placeholder,
          style: UseSmileIDSampleTheme.type.inputFont.with(size: 15, weight: 600)
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
    // Not `.plain`, which fades a disabled label on top of its disabled colours.
    .buttonStyle(UseSmileIDSampleUndimmedButtonStyle())
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

/// Draws the label as given in every state, so a disabled control shows only the colours it chose.
private struct UseSmileIDSampleUndimmedButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}
