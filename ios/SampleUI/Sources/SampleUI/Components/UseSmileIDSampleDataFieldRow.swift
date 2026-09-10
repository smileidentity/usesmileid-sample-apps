import SwiftUI

/// A label/value pair on the verification-details card, optionally with a copy control.
public struct UseSmileIDSampleDataFieldRow: View {
  private let label: String
  private let value: String
  /// Set only where the design colours the value, as the Status row's HTTP code is.
  private let valueColor: Color?
  private let testId: String?
  private let copyTestId: String?
  private let onCopy: (() -> Void)?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(
    label: String,
    value: String,
    valueColor: Color? = nil,
    testId: String? = nil,
    copyTestId: String? = nil,
    onCopy: (() -> Void)? = nil
  ) {
    self.label = label
    self.value = value
    self.valueColor = valueColor
    self.testId = testId
    self.copyTestId = copyTestId
    self.onCopy = onCopy
  }

  public var body: some View {
    // Stacks once type grows, the switch KeyValueEditRow makes: two columns leave each a few characters.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          labelText
          HStack(spacing: SmileSpacing.spacingXs) {
            valueText(alignment: .leading)
            copyButton
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        HStack(spacing: SmileSpacing.spacingXs) {
          labelText
          valueText(alignment: .trailing)
          copyButton
        }
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(minHeight: minHeight)
  }

  private var labelText: some View {
    UseSmileIDSampleText(label, style: UseSmileIDSampleTheme.type.dataFieldLabelFont.with(size: 13))
      .foregroundColor(colors.dataField.label)
      .useSmileIDSampleTestId(testId)
  }

  /// Its own column, or a long value wraps onto the line below its label.
  private func valueText(alignment: TextAlignment) -> some View {
    UseSmileIDSampleText(value, style: valueStyle)
      .foregroundColor(valueColor ?? colors.dataField.value)
      .multilineTextAlignment(alignment)
      .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
  }

  @ViewBuilder
  private var copyButton: some View {
    if let onCopy {
      Button(action: onCopy) {
        UseSmileIDSampleIcon(SmileIcons.copy, tint: colors.textMuted, size: SmileSpacing.sizeIconSm)
          .frame(width: SmileSpacing.sizeIconLg, height: SmileSpacing.sizeIconLg)
          .background(
            RoundedRectangle(cornerRadius: SmileSpacing.radiusSm, style: .continuous)
              .fill(colors.surfaceTile)
          )
          // Grown to the touch minimum and pulled back by the difference, so the row keeps its height.
          .frame(width: Self.target, height: Self.target)
          .contentShape(Rectangle())
          .padding(-(Self.target - SmileSpacing.sizeIconLg) / 2)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Copy \(label)")
      .useSmileIDSampleTestId(copyTestId)
    }
  }

  private static let target: CGFloat = 44

  /// A coloured value is the one the design also weights harder.
  private var valueStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.dataFieldValueFont.with(size: 13, weight: valueColor == nil ? 600 : 700)
  }
}
