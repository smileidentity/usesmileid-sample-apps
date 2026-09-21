import SwiftUI

/// A profile's user-details defaults, which is what seeds the Consent Details Form for its jobs.
public struct UseSmileIDSampleProfileConfigState: Equatable {
  public var organisation: String
  public var defaults: UseSmileIDSampleUserDetails
  public var isActive: Bool
  public var callbackUrl: String
  /// Non-nil while a token session is live: its text replaces the value, and the row stops editing.
  public var callbackOverride: String?

  public init(
    organisation: String,
    defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    isActive: Bool = false,
    callbackUrl: String = "",
    callbackOverride: String? = nil
  ) {
    self.organisation = organisation
    self.defaults = defaults
    self.isActive = isActive
    self.callbackUrl = callbackUrl
    self.callbackOverride = callbackOverride
  }
}

/// Titled with the profile's name; its CTA saves the defaults and activates the profile in one step.
public struct ProfileConfigScreen: View {
  private let state: UseSmileIDSampleProfileConfigState
  private let onFieldChange: (UseSmileIDSampleUserField, String) -> Void
  private let onCallbackUrlChange: (String) -> Void
  private let onBack: () -> Void
  private let onSave: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleProfileConfigState,
    onFieldChange: @escaping (UseSmileIDSampleUserField, String) -> Void,
    onCallbackUrlChange: @escaping (String) -> Void = { _ in },
    onBack: @escaping () -> Void,
    onSave: @escaping () -> Void
  ) {
    self.state = state
    self.onFieldChange = onFieldChange
    self.onCallbackUrlChange = onCallbackUrlChange
    self.onBack = onBack
    self.onSave = onSave
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: state.organisation, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: Self.sectionGap) {
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
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.bottom, Self.sectionGap)
      }
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.profileConfigScreen)
      UseSmileIDSampleButton(
        text: state.isActive ? "Active profile" : "Make this profile active",
        enabled: !state.isActive,
        testId: UseSmileIDSampleTestIds.profileConfigSave,
        action: onSave
      )
      .padding(SmileSpacing.spacingMd)
    }
    .background(colors.background)
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
