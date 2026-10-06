import SwiftUI

/// A profile name and the four user details under it; Create needs the name and both required names.
public struct NewProfileSheet: View {
  @Binding private var draft: UseSmileIDSampleNewProfile
  private let onSave: () -> Void

  @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 17
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(draft: Binding<UseSmileIDSampleNewProfile>, onSave: @escaping () -> Void) {
    _draft = draft
    self.onSave = onSave
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: UseSmileIDSampleStrings.profileSwitchNew, testId: UseSmileIDSampleTestIds.newProfileSheet) {
      field($draft.name, placeholder: UseSmileIDSampleStrings.profileConfigName, icon: SmileIcons.fieldPerson, testId: UseSmileIDSampleTestIds.newProfileName)
      UseSmileIDSampleSectionLabel(UseSmileIDSampleStrings.newProfileSectionDetails)
      field($draft.firstName, placeholder: UseSmileIDSampleStrings.userFieldFirstName, icon: SmileIcons.fieldPerson, testId: UseSmileIDSampleTestIds.newProfileFirstName)
      field($draft.lastName, placeholder: UseSmileIDSampleStrings.userFieldLastName, icon: SmileIcons.fieldPerson, testId: UseSmileIDSampleTestIds.newProfileLastName)
      field(
        $draft.email,
        placeholder: UseSmileIDSampleStrings.userFieldEmailOptional,
        icon: SmileIcons.fieldEmail,
        keyboardType: .emailAddress,
        problem: UseSmileIDSampleContactRules.problem(.email, draft.email),
        testId: UseSmileIDSampleTestIds.newProfileEmail
      )
      field(
        $draft.phone,
        placeholder: UseSmileIDSampleStrings.userFieldPhoneOptional,
        icon: SmileIcons.fieldPhone,
        keyboardType: .phonePad,
        problem: UseSmileIDSampleContactRules.problem(.phone, draft.phone),
        testId: UseSmileIDSampleTestIds.newProfilePhone
      )
      UseSmileIDSampleButton(
        text: UseSmileIDSampleStrings.newProfileCreate,
        enabled: draft.canCreate,
        testId: UseSmileIDSampleTestIds.newProfileSave,
        action: onSave
      )
    }
  }

  /// Each field carries the design's 17pt leading glyph.
  private func field(
    _ value: Binding<String>,
    placeholder: String,
    icon: SmileIcon,
    keyboardType: UIKeyboardType = .default,
    problem: String? = nil,
    testId: String
  ) -> some View {
    UseSmileIDSampleTextInput(
      value: value,
      placeholder: placeholder,
      isError: problem != nil,
      errorMessage: problem,
      keyboardType: keyboardType,
      testId: testId
    ) {
      UseSmileIDSampleIcon(icon, tint: colors.input.placeholder, size: iconSize)
    }
  }
}
