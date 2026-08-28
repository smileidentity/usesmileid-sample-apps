import SwiftUI

/// One picker row; selected takes a pale fill as well as a check, so colour alone never carries it.
public struct UseSmileIDSampleOptionRow: View {
  private let label: String
  private let leadingText: String?
  private let selected: Bool
  private let testId: String?
  private let onTap: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    label: String,
    leadingText: String? = nil,
    selected: Bool,
    testId: String? = nil,
    onTap: @escaping () -> Void
  ) {
    self.label = label
    self.leadingText = leadingText
    self.selected = selected
    self.testId = testId
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingSm) {
        if let leadingText {
          UseSmileIDSampleText(leadingText, style: UseSmileIDSampleTheme.type.textStyleBody.with(size: 19))
        }
        UseSmileIDSampleText(label, style: UseSmileIDSampleTheme.type.textStyleBodyStrong.with(size: 14))
          .foregroundColor(colors.textTitle)
          .frame(maxWidth: .infinity, alignment: .leading)
        if selected {
          UseSmileIDSampleIcon(SmileIcons.check, tint: colors.primary, size: SmileSpacing.sizeIconMd)
        }
      }
      .padding(.horizontal, SmileSpacing.spacingSm)
      .padding(.vertical, SmileSpacing.spacingXs)
      .frame(minHeight: minHeight)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
          .fill(selected ? colors.surfaceTile : .clear)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    .useSmileIDSampleTestId(testId)
  }
}
