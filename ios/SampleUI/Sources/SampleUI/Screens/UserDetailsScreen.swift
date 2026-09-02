import SwiftUI

/// What the Consent Details Form draws, plus what the token has already bound.
public struct UseSmileIDSampleUserDetailsState: Equatable {
  public var productLabel: String
  public var details: UseSmileIDSampleUserDetails
  public var rememberDetails: Bool
  public var requirement: UseSmileIDSampleUserDetailsRequirement

  public init(
    productLabel: String,
    details: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    rememberDetails: Bool = false,
    requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement()
  ) {
    self.productLabel = productLabel
    self.details = details
    self.rememberDetails = rememberDetails
    self.requirement = requirement
  }

  var isSatisfied: Bool {
    details.satisfies(requirement)
  }
}

/// The Consent Details Form, shown for every product before the SDK flow starts.
public struct UserDetailsScreen: View {
  private let state: UseSmileIDSampleUserDetailsState
  private let onFieldChange: (UseSmileIDSampleUserField, String) -> Void
  private let onRememberChange: (Bool) -> Void
  private let onBack: () -> Void
  private let onContinue: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleUserDetailsState,
    onFieldChange: @escaping (UseSmileIDSampleUserField, String) -> Void,
    onRememberChange: @escaping (Bool) -> Void,
    onBack: @escaping () -> Void,
    onContinue: @escaping () -> Void
  ) {
    self.state = state
    self.onFieldChange = onFieldChange
    self.onRememberChange = onRememberChange
    self.onBack = onBack
    self.onContinue = onContinue
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: state.productLabel, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
          fields
          hint
          if state.isSatisfied {
            rememberCard
          }
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.vertical, SmileSpacing.spacingXs)
      }
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.userDetailsScreen)
      UseSmileIDSampleButton(
        text: "Continue",
        enabled: state.isSatisfied,
        testId: UseSmileIDSampleTestIds.userDetailsContinue,
        action: onContinue
      )
      .padding(SmileSpacing.spacingMd)
    }
    .background(colors.background)
  }

  private var fields: some View {
    UseSmileIDSampleSectionSurface(label: "YOUR DETAILS") {
      ForEach(Array(UseSmileIDSampleUserField.allCases.enumerated()), id: \.element) { index, field in
        if index > 0 {
          UseSmileIDSampleRowDivider()
        }
        row(field)
      }
    }
  }

  /// A supplied value is vaulted, so it is shown as provided rather than prefilled.
  private func row(_ field: UseSmileIDSampleUserField) -> some View {
    let supplied = state.requirement.supplies(field)
    return UseSmileIDSampleKeyValueEditRow(
      label: state.requirement.label(for: field),
      value: Binding(
        get: { supplied ? "" : field.read(state.details) },
        set: { onFieldChange(field, $0) }
      ),
      placeholder: supplied ? "Provided by token" : field.placeholder,
      enabled: !supplied,
      keyboardType: Self.keyboard(for: field),
      testId: UseSmileIDSampleTestIds.userDetailsField(field.id)
    )
  }

  private var hint: some View {
    UseSmileIDSampleText(
      state.isSatisfied ? "Tap any field to edit." : state.requirement.prompt,
      style: UseSmileIDSampleTheme.type.textStyleCaption
    )
    .foregroundColor(colors.textMuted)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.userDetailsHint)
  }

  /// One line of body text beside the switch, so not a `SettingRow`.
  private var rememberCard: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleText(
        "Remember these details for next time",
        style: UseSmileIDSampleTheme.type.textStyleSubtitle.with(size: 13.5)
      )
      .foregroundColor(colors.textBody)
      .frame(maxWidth: .infinity, alignment: .leading)
      UseSmileIDSampleSwitch(
        isOn: Binding(get: { state.rememberDetails }, set: onRememberChange),
        testId: UseSmileIDSampleTestIds.rememberDetailsSwitch
      )
    }
    .padding(.leading, SmileSpacing.spacingMd)
    .padding(.trailing, SmileSpacing.spacingSm)
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .fill(colors.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
  }

  private static func keyboard(for field: UseSmileIDSampleUserField) -> UIKeyboardType {
    switch field {
    case .email: .emailAddress
    case .phone: .phonePad
    default: .default
    }
  }
}
