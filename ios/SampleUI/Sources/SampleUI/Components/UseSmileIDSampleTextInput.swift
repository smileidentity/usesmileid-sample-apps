import SwiftUI

/// A single-line field on the input tokens; error outranks focus, so tapping back in does not hide the message.
public struct UseSmileIDSampleTextInput<Leading: View, Trailing: View>: View {
  @Binding private var value: String
  private let placeholder: String
  private let enabled: Bool
  private let isError: Bool
  private let errorMessage: String?
  private let keyboardType: UIKeyboardType
  private let masked: Bool
  private let testId: String?
  private let leading: Leading
  private let trailing: Trailing

  @FocusState private var focused: Bool
  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlMd
  @ScaledMetric(relativeTo: .body) private var leadingSize: CGFloat = 17
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    value: Binding<String>,
    placeholder: String = "",
    enabled: Bool = true,
    isError: Bool = false,
    errorMessage: String? = nil,
    keyboardType: UIKeyboardType = .default,
    // Masks the value and marks the field a password, keeping a credential out of screenshots and hierarchy dumps.
    masked: Bool = false,
    testId: String? = nil,
    @ViewBuilder leading: () -> Leading = { EmptyView() },
    @ViewBuilder trailing: () -> Trailing = { EmptyView() }
  ) {
    _value = value
    self.placeholder = placeholder
    self.enabled = enabled
    self.isError = isError
    self.errorMessage = errorMessage
    self.keyboardType = keyboardType
    self.masked = masked
    self.testId = testId
    self.leading = leading()
    self.trailing = trailing()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.space4) {
      HStack(spacing: SmileSpacing.spacingXs) {
        // The leading glyph the new-profile fields carry; the KYC form's inputs leave it empty.
        if Leading.self != EmptyView.self {
          leading
            .foregroundColor(colors.input.placeholder)
            .frame(minWidth: leadingSize, minHeight: leadingSize)
        }
        field
        trailing.foregroundColor(colors.input.placeholder)
      }
      .padding(.horizontal, SmileSpacing.spacingMd)
      .padding(.vertical, SmileSpacing.spacingSm)
      .frame(minHeight: minHeight)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
          .fill(enabled ? colors.input.background : colors.surfaceMuted)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
          .strokeBorder(borderColor, lineWidth: borderWidth)
      )

      if isError, let errorMessage, !errorMessage.isEmpty {
        UseSmileIDSampleText(errorMessage, style: UseSmileIDSampleTheme.type.textStyleCaption)
          .foregroundColor(colors.input.borderError)
          .padding(.leading, SmileSpacing.spacingMd)
      }
    }
  }

  private var field: some View {
    // Sized by a line of text, not the field: UITextField pads itself, which made the input 2 taller than Compose's.
    UseSmileIDSampleText(value.isEmpty ? placeholder : " ", style: UseSmileIDSampleTheme.type.inputFont)
      .foregroundColor(value.isEmpty ? colors.input.placeholder : .clear)
      .accessibilityHidden(!value.isEmpty)
      .frame(maxWidth: .infinity, alignment: .leading)
      .overlay(alignment: .leading) {
        // SecureField rather than a masking transform: it stops the system offering to learn the value.
        Group {
          if masked {
            SecureField("", text: $value)
          } else {
            TextField("", text: $value)
          }
        }
        .font(UseSmileIDSampleFonts.font(UseSmileIDSampleTheme.type.inputFont))
        .foregroundColor(enabled ? colors.input.text : colors.textMuted)
        .keyboardType(masked ? .default : keyboardType)
        .autocorrectionDisabled(masked)
        // A capitalised first character silently corrupts a credential the user typed correctly.
        .textInputAutocapitalization(masked ? .never : nil)
        .accentColor(colors.input.borderFocus)
        .focused($focused)
        .disabled(!enabled)
        .useSmileIDSampleTestId(testId)
      }
  }

  private var borderColor: Color {
    if isError {
      return colors.input.borderError
    }
    return focused ? colors.input.borderFocus : colors.input.border
  }

  private var borderWidth: CGFloat {
    focused || isError ? SmileSpacing.borderWidthThin : SmileSpacing.borderWidthHairline
  }
}
