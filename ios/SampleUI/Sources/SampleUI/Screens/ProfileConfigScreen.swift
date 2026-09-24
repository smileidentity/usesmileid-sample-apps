import SwiftUI

/// A profile's name and user-details defaults, which is what seeds the Consent Details Form for its jobs.
public struct UseSmileIDSampleProfileConfigState: Equatable {
  /// The app bar's title: the saved profile's, so it does not change as the name is typed.
  public var title: String
  public var organisation: String
  public var defaults: UseSmileIDSampleUserDetails
  public var isActive: Bool
  /// Whether anything differs from what is stored, which is all the active profile's Save can act on.
  public var changed: Bool
  public var callbackUrl: String
  /// Non-nil while a token session is live: its text replaces the value, and the row stops editing.
  public var callbackOverride: String?

  public init(
    title: String,
    organisation: String,
    defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    isActive: Bool = false,
    changed: Bool = false,
    callbackUrl: String = "",
    callbackOverride: String? = nil
  ) {
    self.title = title
    self.organisation = organisation
    self.defaults = defaults
    self.isActive = isActive
    self.changed = changed
    self.callbackUrl = callbackUrl
    self.callbackOverride = callbackOverride
  }
}

/// Titled with the profile's name; its one CTA saves the active profile's edits, or saves and activates any other.
public struct ProfileConfigScreen: View {
  private let state: UseSmileIDSampleProfileConfigState
  private let onFieldChange: (UseSmileIDSampleUserField, String) -> Void
  private let onOrganisationChange: (String) -> Void
  private let onCallbackUrlChange: (String) -> Void
  private let onBack: () -> Void
  private let onSave: () -> Void
  private let onDelete: (() -> Void)?

  @State private var confirmingDelete = false
  @Environment(\.useSmileIDSampleColors) private var colors

  /// A nil `onDelete` hides the row, for a host that offers no delete.
  public init(
    state: UseSmileIDSampleProfileConfigState,
    onFieldChange: @escaping (UseSmileIDSampleUserField, String) -> Void,
    onOrganisationChange: @escaping (String) -> Void = { _ in },
    onCallbackUrlChange: @escaping (String) -> Void = { _ in },
    onBack: @escaping () -> Void,
    onSave: @escaping () -> Void,
    onDelete: (() -> Void)? = nil
  ) {
    self.state = state
    self.onFieldChange = onFieldChange
    self.onOrganisationChange = onOrganisationChange
    self.onCallbackUrlChange = onCallbackUrlChange
    self.onBack = onBack
    self.onSave = onSave
    self.onDelete = onDelete
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: state.title, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: Self.sectionGap) {
          UseSmileIDSampleSectionLabel("PROFILE")
          UseSmileIDSampleSectionSurface {
            UseSmileIDSampleKeyValueEditRow(
              label: "Organisation",
              value: Binding(get: { state.organisation }, set: onOrganisationChange),
              placeholder: "Shown on the consent screen",
              testId: UseSmileIDSampleTestIds.profileConfigName
            )
          }
          // The label stays here: the section gap, not the surface's own spacing, separates it from the card.
          UseSmileIDSampleSectionLabel("USER DETAILS \u{2014} ATTACHED TO EVERY JOB")
          UseSmileIDSampleSectionSurface {
            ForEach(Array(UseSmileIDSampleUserField.allCases.enumerated()), id: \.element) { index, field in
              if index > 0 {
                UseSmileIDSampleRowDivider()
              }
              row(field)
            }
          }
          // Its own section, not a row in the card above: a webhook URL is not a user detail.
          UseSmileIDSampleSectionLabel("CALLBACK URL")
          UseSmileIDSampleSectionSurface {
            callbackRow
          }
          if onDelete != nil {
            UseSmileIDSampleDestructiveRow(
              text: "Delete profile",
              testId: UseSmileIDSampleTestIds.profileConfigDelete,
              action: { confirmingDelete = true }
            )
          }
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.bottom, Self.sectionGap)
      }
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.profileConfigScreen)
      // One slot, as the design has it: the active profile saves its edits, any other also becomes active.
      UseSmileIDSampleButton(
        text: state.isActive ? "Save changes" : "Use this profile",
        enabled: state.changed || !state.isActive,
        testId: UseSmileIDSampleTestIds.profileConfigSave,
        action: onSave
      )
      .padding(SmileSpacing.spacingMd)
    }
    .background(colors.background)
    .useSmileIDSampleConfirmation(
      isPresented: $confirmingDelete,
      title: "Delete \(state.title)?",
      message: "Its details and callback URL are removed from this device.",
      confirmLabel: "Delete",
      confirmTestId: UseSmileIDSampleTestIds.profileDeleteConfirm,
      onConfirm: { onDelete?() }
    )
  }

  private var callbackRow: some View {
    UseSmileIDSampleKeyValueEditRow(
      label: "Webhook URL",
      value: Binding(
        get: { state.callbackOverride == nil ? state.callbackUrl : "" },
        set: onCallbackUrlChange
      ),
      placeholder: state.callbackOverride ?? "Uses your portal default",
      required: false,
      enabled: state.callbackOverride == nil,
      keyboardType: .URL,
      testId: UseSmileIDSampleTestIds.profileConfigCallbackUrl
    )
  }

  private func row(_ field: UseSmileIDSampleUserField) -> some View {
    UseSmileIDSampleKeyValueEditRow(
      label: field.label,
      value: Binding(get: { field.read(state.defaults) }, set: { onFieldChange(field, $0) }),
      placeholder: field.placeholder,
      required: field.required,
      keyboardType: field.keyboardType,
      testId: UseSmileIDSampleTestIds.profileConfigField(field.id)
    )
  }

  /// The design's gap between the header, the label, the card and the CTA.
  private static let sectionGap: CGFloat = 14
}
