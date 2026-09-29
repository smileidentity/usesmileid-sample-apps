import SwiftUI

public struct UseSmileIDSampleKycIdFormState {
  public var productLabel: String
  public var family: UseSmileIDSampleCatalogueFamily
  public var details: UseSmileIDSampleIdDetails
  /// Whether the chosen country's list is still arriving, which is what the second trigger's placeholder says.
  public var countryListLoading: Bool

  public init(
    productLabel: String,
    family: UseSmileIDSampleCatalogueFamily = .kyc,
    details: UseSmileIDSampleIdDetails = UseSmileIDSampleIdDetails(),
    countryListLoading: Bool = false
  ) {
    self.productLabel = productLabel
    self.family = family
    self.details = details
    self.countryListLoading = countryListLoading
  }
}

/// The ID-details form: an ID type and number for KYC, a document and how to capture it otherwise.
public struct KycIdFormScreen: View {
  private let state: UseSmileIDSampleKycIdFormState
  private let onCountryTap: () -> Void
  private let onIdTypeTap: () -> Void
  private let onDocumentTap: () -> Void
  private let onCaptureAsTap: () -> Void
  private let onIdNumberChange: (String) -> Void
  private let onBack: () -> Void
  private let onContinue: () -> Void
  private let onToken: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleKycIdFormState,
    onCountryTap: @escaping () -> Void,
    onIdTypeTap: @escaping () -> Void,
    onDocumentTap: @escaping () -> Void = {},
    onCaptureAsTap: @escaping () -> Void = {},
    onIdNumberChange: @escaping (String) -> Void,
    onBack: @escaping () -> Void,
    onContinue: @escaping () -> Void,
    onToken: @escaping () -> Void
  ) {
    self.state = state
    self.onCountryTap = onCountryTap
    self.onIdTypeTap = onIdTypeTap
    self.onDocumentTap = onDocumentTap
    self.onCaptureAsTap = onCaptureAsTap
    self.onIdNumberChange = onIdNumberChange
    self.onBack = onBack
    self.onContinue = onContinue
    self.onToken = onToken
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: state.productLabel, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
          UseSmileIDSampleSectionLabel("COUNTRY")
          countryTrigger
          switch state.family {
          case .kyc:
            UseSmileIDSampleSectionLabel("ID TYPE")
            idTypeTrigger
            UseSmileIDSampleSectionLabel("ID NUMBER")
            idNumberInput
          case .document:
            UseSmileIDSampleSectionLabel("DOCUMENT")
            documentTrigger
            UseSmileIDSampleSectionLabel("CAPTURE AS")
            captureAsTrigger
          case .passport:
            EmptyView()
          }
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
      }
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.kycFormScreen)
      // An inset rather than an overlay: the button grows with Dynamic Type and would cover the last field.
      .safeAreaInset(edge: .bottom, alignment: .trailing) {
        UseSmileIDSampleFloatingTokenButton(action: onToken)
          .padding(SmileSpacing.spacingMd)
      }
      UseSmileIDSampleButton(
        text: "Continue",
        enabled: state.details.isComplete(state.family),
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
      value: state.details.country?.name,
      placeholder: "Select country",
      testId: UseSmileIDSampleTestIds.countryTrigger,
      onTap: onCountryTap
    ) { _ in
      UseSmileIDSampleTriggerEmoji(state.details.country?.flag ?? "\u{1F30D}")
    }
  }

  private var idTypeTrigger: some View {
    UseSmileIDSampleSelectTrigger(
      value: state.details.idType?.label,
      placeholder: secondPlaceholder(loading: "Loading ID types\u{2026}", ready: "Select ID type"),
      enabled: state.details.country != nil,
      testId: UseSmileIDSampleTestIds.idTypeTrigger,
      onTap: onIdTypeTap
    ) { tint in
      // Not the design's ID-card emoji, whose glyph is unavailable on older runtimes; changing it is a design call.
      UseSmileIDSampleIcon(SmileIcons.biometricKyc, tint: tint, size: SmileSpacing.sizeIconMd)
    }
  }

  private var idNumberInput: some View {
    let error = UseSmileIDSampleIdNumberHint.error(state.details.idType, state.details.idNumber)
    return UseSmileIDSampleTextInput(
      value: Binding(get: { state.details.idNumber }, set: onIdNumberChange),
      placeholder: UseSmileIDSampleIdNumberHint.placeholder(state.details.idType),
      enabled: state.details.idType != nil,
      isError: error != nil,
      errorMessage: error,
      testId: UseSmileIDSampleTestIds.idNumberInput,
      errorTestId: UseSmileIDSampleTestIds.idNumberError
    )
    // An ID number is upper-case everywhere it is printed.
    .textInputAutocapitalization(.characters)
    // An alphanumeric ID is exactly what autocorrect rewrites into a word.
    .autocorrectionDisabled()
  }

  private var documentTrigger: some View {
    UseSmileIDSampleSelectTrigger(
      value: state.details.document?.name,
      placeholder: secondPlaceholder(loading: "Loading documents\u{2026}", ready: "Select document"),
      enabled: state.details.country != nil,
      testId: UseSmileIDSampleTestIds.documentTrigger,
      onTap: onDocumentTap
    ) { tint in
      UseSmileIDSampleIcon(SmileIcons.documentVerification, tint: tint, size: SmileSpacing.sizeIconMd)
    }
  }

  private var captureAsTrigger: some View {
    UseSmileIDSampleSelectTrigger(
      value: state.details.captureAs == .genericDocument
        ? "Generic document: \(state.details.genericDocument.displayName)"
        : state.details.captureAs.label,
      placeholder: UseSmileIDSampleCaptureAs.genericDocument.label,
      enabled: state.details.document != nil,
      testId: UseSmileIDSampleTestIds.captureAsTrigger,
      onTap: onCaptureAsTap
    ) { tint in
      UseSmileIDSampleIcon(SmileIcons.preview, tint: tint, size: SmileSpacing.sizeIconMd)
    }
  }

  /// Enabled while loading, with a muted "Loading…" in place of the prompt, so the form never looks stuck.
  private func secondPlaceholder(loading: String, ready: String) -> String {
    if state.details.country == nil {
      return "Choose a country first"
    }
    return state.countryListLoading ? loading : ready
  }
}
