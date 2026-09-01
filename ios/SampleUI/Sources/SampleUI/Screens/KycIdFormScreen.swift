import SwiftUI

public struct UseSmileIDSampleKycIdFormState: Equatable {
  public var productLabel: String
  public var details: UseSmileIDSampleIdDetails

  public init(productLabel: String, details: UseSmileIDSampleIdDetails = UseSmileIDSampleIdDetails()) {
    self.productLabel = productLabel
    self.details = details
  }
}

/// The ID-details form. ID type is disabled until a country is chosen, because the types depend on it.
public struct KycIdFormScreen: View {
  private let state: UseSmileIDSampleKycIdFormState
  private let onCountryTap: () -> Void
  private let onIdTypeTap: () -> Void
  private let onIdNumberChange: (String) -> Void
  private let onBack: () -> Void
  private let onContinue: () -> Void
  private let onToken: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleKycIdFormState,
    onCountryTap: @escaping () -> Void,
    onIdTypeTap: @escaping () -> Void,
    onIdNumberChange: @escaping (String) -> Void,
    onBack: @escaping () -> Void,
    onContinue: @escaping () -> Void,
    onToken: @escaping () -> Void
  ) {
    self.state = state
    self.onCountryTap = onCountryTap
    self.onIdTypeTap = onIdTypeTap
    self.onIdNumberChange = onIdNumberChange
    self.onBack = onBack
    self.onContinue = onContinue
    self.onToken = onToken
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: state.productLabel, onBack: onBack)
      ZStack(alignment: .bottomTrailing) {
        ScrollView {
          VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
            UseSmileIDSampleSectionLabel("COUNTRY")
            countryTrigger
            UseSmileIDSampleSectionLabel("ID TYPE")
            idTypeTrigger
            UseSmileIDSampleSectionLabel("ID NUMBER")
            idNumberInput
          }
          .padding(.horizontal, SmileSpacing.spacingMd)
          .padding(.vertical, SmileSpacing.spacingSm)
        }
        .useSmileIDSampleTestId(UseSmileIDSampleTestIds.kycFormScreen)
        UseSmileIDSampleFloatingTokenButton(action: onToken)
          .padding(SmileSpacing.spacingMd)
      }
      UseSmileIDSampleButton(
        text: "Continue",
        enabled: state.details.isComplete,
        testId: UseSmileIDSampleTestIds.kycContinue,
        action: onContinue
      )
      .padding(SmileSpacing.spacingMd)
    }
    .background(colors.background)
  }

  /// The design leads with the chosen country's flag, falling back to a globe.
  private var countryTrigger: some View {
    UseSmileIDSampleSelectTrigger(
      value: state.details.country?.label,
      placeholder: "Select country",
      testId: UseSmileIDSampleTestIds.countryTrigger,
      onTap: onCountryTap
    ) {
      UseSmileIDSampleTriggerEmoji(state.details.country?.flag ?? "\u{1F30D}")
    }
  }

  private var idTypeTrigger: some View {
    UseSmileIDSampleSelectTrigger(
      value: state.details.idType?.label,
      placeholder: state.details.country == nil ? "Choose a country first" : "Select ID type",
      enabled: state.details.country != nil,
      testId: UseSmileIDSampleTestIds.idTypeTrigger,
      onTap: onIdTypeTap
    ) {
      // Not the design's ID-card emoji: Emoji 14 is iOS 15.4 and this package's floor is 15.0.
      UseSmileIDSampleIcon(
        SmileIcons.biometricKyc,
        tint: state.details.country == nil ? colors.textMuted : colors.textTitle,
        size: SmileSpacing.sizeIconMd
      )
    }
  }

  private var idNumberInput: some View {
    UseSmileIDSampleTextInput(
      value: Binding(get: { state.details.idNumber }, set: onIdNumberChange),
      placeholder: "Enter ID number",
      testId: UseSmileIDSampleTestIds.idNumberInput
    )
    // An ID number is upper-case everywhere it is printed, as the Compose twin also sets.
    .textInputAutocapitalization(.characters)
  }
}
