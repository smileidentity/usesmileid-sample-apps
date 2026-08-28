import SwiftUI

/// A single-line field on the input tokens.
///
/// Error outranks focus, so tapping back into a rejected field does not hide the message.
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
    // Masks the value and marks the field a password, keeping a credential out of screenshots
    // and out of the view hierarchy an automated run dumps on failure.
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
    ZStack(alignment: .leading) {
      if value.isEmpty {
        UseSmileIDSampleText(placeholder, style: UseSmileIDSampleTheme.type.inputFont)
          .foregroundColor(colors.input.placeholder)
      }
      // SecureField rather than a masking transform: it is what stops the system offering to
      // learn the value, and what keeps it out of a screenshot.
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
    .frame(maxWidth: .infinity, alignment: .leading)
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
