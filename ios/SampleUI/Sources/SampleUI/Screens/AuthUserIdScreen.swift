import SwiftUI

/// SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user.
public struct AuthUserIdScreen: View {
  private let userId: String
  private let previousUserIds: [String]
  private let onUserIdChange: (String) -> Void
  private let onRegister: () -> Void
  private let onBack: () -> Void
  private let onContinue: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    userId: String,
    previousUserIds: [String],
    onUserIdChange: @escaping (String) -> Void,
    onRegister: @escaping () -> Void,
    onBack: @escaping () -> Void,
    onContinue: @escaping () -> Void
  ) {
    self.userId = userId
    self.previousUserIds = previousUserIds
    self.onUserIdChange = onUserIdChange
    self.onRegister = onRegister
    self.onBack = onBack
    self.onContinue = onContinue
  }

  private var chosen: String {
    userId.trimmingCharacters(in: .whitespaces)
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: UseSmileIDSampleProduct.smartSelfieAuth.label, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
          UseSmileIDSampleProductTile(.smartSelfieAuth, side: SmileSpacing.space64)
            .frame(maxWidth: .infinity)
          if previousUserIds.isEmpty {
            heading(UseSmileIDSampleStrings.authUserIdEmptyTitle)
            note(UseSmileIDSampleStrings.authUserIdPreviousBody)
            heading(UseSmileIDSampleStrings.authUserIdRun)
            registerCard
            or
            userIdField
          } else {
            userIdField
            or
            heading(UseSmileIDSampleStrings.authUserIdPrevious)
            note(UseSmileIDSampleStrings.authUserIdPreviousBody)
            ForEach(Array(previousUserIds.enumerated()), id: \.element) { index, previous in
              UseSmileIDSampleOptionRow(
                label: previous,
                selected: previous == chosen,
                testId: UseSmileIDSampleTestIds.authUserIdOption(index),
                onTap: { onUserIdChange(previous) }
              )
            }
          }
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.vertical, SmileSpacing.spacingLg)
      }
      UseSmileIDSampleButton(
        text: UseSmileIDSampleStrings.commonContinue,
        enabled: !chosen.isEmpty,
        testId: UseSmileIDSampleTestIds.authUserIdContinue,
        action: onContinue
      )
      .padding(SmileSpacing.spacingMd)
    }
    .background(colors.background)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.authUserIdScreen)
  }

  private var userIdField: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
      heading(UseSmileIDSampleStrings.authUserIdEnter)
      UseSmileIDSampleTextInput(
        value: Binding(get: { userId }, set: onUserIdChange),
        placeholder: UseSmileIDSampleStrings.authUserIdPlaceholder,
        keyboardType: .asciiCapable,
        testId: UseSmileIDSampleTestIds.authUserIdInput
      )
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
    }
  }

  private var registerCard: some View {
    Button(action: onRegister) {
      HStack(spacing: SmileSpacing.spacingSm) {
        UseSmileIDSampleProductTile(.smartSelfieEnrollment)
        UseSmileIDSampleText(UseSmileIDSampleProduct.smartSelfieEnrollment.label, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
          .foregroundColor(colors.card.title)
        Spacer(minLength: 0)
      }
      .padding(SmileSpacing.spacingSm)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .fill(colors.card.background)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.authUserIdRegister)
  }

  private var or: some View {
    UseSmileIDSampleText(UseSmileIDSampleStrings.authUserIdOr, style: UseSmileIDSampleTheme.type.textStyleCaption)
      .foregroundColor(colors.textMuted)
      .frame(maxWidth: .infinity)
  }

  private func heading(_ text: String) -> some View {
    UseSmileIDSampleText(text, style: UseSmileIDSampleTheme.type.textStyleTitle)
      .foregroundColor(colors.textTitle)
      .accessibilityAddTraits(.isHeader)
  }

  private func note(_ text: String) -> some View {
    UseSmileIDSampleText(text, style: UseSmileIDSampleTheme.type.textStyleCaption)
      .foregroundColor(colors.textMuted)
  }
}
