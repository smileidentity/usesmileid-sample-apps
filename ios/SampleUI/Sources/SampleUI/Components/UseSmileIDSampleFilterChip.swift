import SwiftUI

/// A status filter with its live count, which is its own node because a delete is asserted on it.
public struct UseSmileIDSampleFilterChip: View {
  private let label: String
  private let count: Int
  private let selected: Bool
  private let testId: String?
  private let countTestId: String?
  private let onTap: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space32
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    label: String,
    count: Int,
    selected: Bool,
    testId: String? = nil,
    countTestId: String? = nil,
    onTap: @escaping () -> Void
  ) {
    self.label = label
    self.count = count
    self.selected = selected
    self.testId = testId
    self.countTestId = countTestId
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingXxs) {
        UseSmileIDSampleText(label, style: chipStyle)
          .foregroundColor(selected ? colors.onPrimary : colors.filterChip.label)
        UseSmileIDSampleText(
          "\(count)",
          style: UseSmileIDSampleTheme.type.textStyleOverline.with(size: smileLabelSize, tracking: smileLabelTracking)
        )
        // The design file's muted grey, deliberately not filter-chip.value's blue.
        .foregroundColor(selected ? colors.onPrimary : colors.textMuted)
        .useSmileIDSampleTestId(countTestId)
      }
      .padding(.horizontal, SmileSpacing.spacingSm)
      .padding(.vertical, SmileSpacing.spacingXs)
      .frame(minHeight: minHeight)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.chip, style: .continuous)
          .fill(selected ? colors.primary : colors.filterChip.background)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.chip, style: .continuous)
          .strokeBorder(selected ? .clear : colors.cardStroke, lineWidth: smileCardStrokeWidth)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    .useSmileIDSampleTestId(testId)
  }

  private var chipStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.filterChipFont.with(size: 12.5, weight: 700)
  }
}
