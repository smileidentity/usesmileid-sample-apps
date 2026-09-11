import SwiftUI

/// A label and a value that edits in place with a caret, rather than pushing a form.
public struct UseSmileIDSampleKeyValueEditRow: View {
  private let label: String
  @Binding private var value: String
  private let placeholder: String
  private let required: Bool
  private let enabled: Bool
  private let keyboardType: UIKeyboardType
  private let testId: String?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(
    label: String,
    value: Binding<String>,
    placeholder: String = "",
    required: Bool = false,
    enabled: Bool = true,
    keyboardType: UIKeyboardType = .default,
    testId: String? = nil
  ) {
    self.label = label
    _value = value
    self.placeholder = placeholder
    self.required = required
    self.enabled = enabled
    self.keyboardType = keyboardType
    self.testId = testId
  }

  public var body: some View {
    // Stacks once type grows; SwiftUI has no FlowRow on this floor, so the switch is explicit.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          labelText
          field.frame(maxWidth: .infinity, alignment: .leading)
        }
      } else {
        HStack(spacing: SmileSpacing.spacingSm) {
          labelText
          field.frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
    }
    .padding(.horizontal, Self.paddingX)
    .padding(.vertical, Self.paddingY)
    .frame(minHeight: minHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(colors.surface)
  }

  private var labelText: some View {
    UseSmileIDSampleText(
      required ? "\(label) *" : label,
      style: UseSmileIDSampleTheme.type.textStyleSubtitle.with(size: 13.5)
    )
    .foregroundColor(colors.textTitle)
  }

  private var field: some View {
    // A text field fills its column, so the row's own alignment cannot place the text: this does.
    let stacked = sizeCategory.isAccessibilityCategory
    return ZStack(alignment: stacked ? .leading : .trailing) {
      if value.isEmpty {
        UseSmileIDSampleText(placeholder, style: rowStyle)
          .foregroundColor(colors.textMuted)
      }
      TextField("", text: $value)
        .multilineTextAlignment(stacked ? .leading : .trailing)
        .font(UseSmileIDSampleFonts.font(rowStyle))
        .foregroundColor(enabled ? colors.textTitle : colors.textMuted)
        .keyboardType(keyboardType)
        .accentColor(colors.primary)
        .disabled(!enabled)
        .useSmileIDSampleTestId(testId)
    }
  }

  private var rowStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.textStyleSubtitle.with(size: 13.5)
  }

  private static var paddingX: CGFloat {
    15
  }

  private static var paddingY: CGFloat {
    14
  }
}
