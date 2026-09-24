import SwiftUI

/// What the Consent Details Form draws, plus what the token has already bound.
public struct UseSmileIDSampleUserDetailsState: Equatable {
  public var productLabel: String
  public var details: UseSmileIDSampleUserDetails
  /// Who this run is for; nil while there is no profile, when the form offers to create one.
  public var profile: UseSmileIDSampleProfile?
  public var profileIndex: Int
  public var saveToProfile: Bool
  /// The new profile's name, asked only while there is no profile.
  public var organisation: String
  public var requirement: UseSmileIDSampleUserDetailsRequirement

  public init(
    productLabel: String,
    details: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    profile: UseSmileIDSampleProfile? = nil,
    profileIndex: Int = 0,
    saveToProfile: Bool = true,
    organisation: String = "",
    requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement()
  ) {
    self.productLabel = productLabel
    self.details = details
    self.profile = profile
    self.profileIndex = profileIndex
    self.saveToProfile = saveToProfile
    self.organisation = organisation
    self.requirement = requirement
  }

  var isSatisfied: Bool {
    details.satisfies(requirement)
  }

  /// Only once there is something to keep: valid details that no profile holds yet.
  var offersSave: Bool {
    isSatisfied && details != profile?.defaults
  }

  var saveLabel: String {
    profile.map { "Save to \($0.title)" } ?? "Save as a new profile"
  }
}

/// The Consent Details Form, shown for every product before the SDK flow starts.
public struct UserDetailsScreen: View {
  private let state: UseSmileIDSampleUserDetailsState
  private let onFieldChange: (UseSmileIDSampleUserField, String) -> Void
  private let onSaveToProfileChange: (Bool) -> Void
  private let onOrganisationChange: (String) -> Void
  private let onProfileTap: () -> Void
  private let onBack: () -> Void
  private let onContinue: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleUserDetailsState,
    onFieldChange: @escaping (UseSmileIDSampleUserField, String) -> Void,
    onSaveToProfileChange: @escaping (Bool) -> Void,
    onOrganisationChange: @escaping (String) -> Void = { _ in },
    onProfileTap: @escaping () -> Void,
    onBack: @escaping () -> Void,
    onContinue: @escaping () -> Void
  ) {
    self.state = state
    self.onFieldChange = onFieldChange
    self.onSaveToProfileChange = onSaveToProfileChange
    self.onOrganisationChange = onOrganisationChange
    self.onProfileTap = onProfileTap
    self.onBack = onBack
    self.onContinue = onContinue
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: state.productLabel, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
          profileRow
          fields
          hint
          if state.offersSave {
            rememberCard
          }
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
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

  /// Says whose details these are, and switches in one tap: the whole reason profiles exist.
  private var profileRow: some View {
    UseSmileIDSampleProfileRow(
      organisation: state.profile?.title ?? UseSmileIDSampleProfiles.noProfileLabel,
      supportingText: state.profile == nil ? "Your details below will create one" : "Tap to switch profile",
      initials: state.profile?.initials ?? "",
      selected: false,
      avatarColor: useSmileIDSampleAvatarColor(profileIndex: state.profileIndex),
      testId: UseSmileIDSampleTestIds.userDetailsProfile,
      onTap: onProfileTap
    ) {
      UseSmileIDSampleIcon(SmileIcons.chevronDown, tint: colors.textMuted, size: 12)
    }
  }

  private var fields: some View {
    UseSmileIDSampleSectionSurface(label: "YOUR DETAILS") {
      if state.profile == nil {
        UseSmileIDSampleKeyValueEditRow(
          label: "Organisation (optional)",
          value: Binding(get: { state.organisation }, set: onOrganisationChange),
          placeholder: "Shown on the consent screen",
          testId: UseSmileIDSampleTestIds.userDetailsField(Self.organisationFieldId)
        )
        UseSmileIDSampleRowDivider()
      }
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
      keyboardType: field.keyboardType,
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
        state.saveLabel,
        style: UseSmileIDSampleTheme.type.textStyleSubtitle.with(size: 13.5)
      )
      .foregroundColor(colors.textBody)
      .frame(maxWidth: .infinity, alignment: .leading)
      UseSmileIDSampleSwitch(
        isOn: Binding(get: { state.saveToProfile }, set: onSaveToProfileChange),
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
}

extension UserDetailsScreen {
  /// The organisation row's id suffix, beside the four user fields'.
  static let organisationFieldId = "organisation"
}

extension UseSmileIDSampleUserField {
  var keyboardType: UIKeyboardType {
    switch self {
    case .email: .emailAddress
    case .phone: .phonePad
    default: .default
    }
  }
}
