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
    HStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleText(label, style: UseSmileIDSampleTheme.type.dataFieldLabelFont.with(size: 13))
        .foregroundColor(colors.dataField.label)
        .useSmileIDSampleTestId(testId)

      // Its own column, or a long value wraps onto the line below its label.
      UseSmileIDSampleText(value, style: valueStyle)
        .foregroundColor(valueColor ?? colors.dataField.value)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)

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
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(minHeight: minHeight)
  }

  private static let target: CGFloat = 44

  /// A coloured value is the one the design also weights harder.
  private var valueStyle: SmileTextStyle {
    let style = UseSmileIDSampleTheme.type.dataFieldValueFont.with(size: 13)
    return SmileTextStyle(
      family: style.family,
      weight: valueColor == nil ? 600 : 700,
      size: style.size,
      lineHeight: style.lineHeight,
      tracking: style.tracking
    )
  }
}
