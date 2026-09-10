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
    UseSmileIDSampleBottomSheet(title: "New profile", testId: UseSmileIDSampleTestIds.newProfileSheet) {
      field($draft.name, placeholder: "Profile name", icon: SmileIcons.fieldPerson, testId: UseSmileIDSampleTestIds.newProfileName)
      UseSmileIDSampleSectionLabel("USER DETAILS")
      field($draft.firstName, placeholder: "First name", icon: SmileIcons.fieldPerson, testId: UseSmileIDSampleTestIds.newProfileFirstName)
      field($draft.lastName, placeholder: "Last name", icon: SmileIcons.fieldPerson, testId: UseSmileIDSampleTestIds.newProfileLastName)
      field(
        $draft.email,
        placeholder: "Email (optional)",
        icon: SmileIcons.fieldEmail,
        keyboardType: .emailAddress,
        testId: UseSmileIDSampleTestIds.newProfileEmail
      )
      field(
        $draft.phone,
        placeholder: "Phone (optional)",
        icon: SmileIcons.fieldPhone,
        keyboardType: .phonePad,
        testId: UseSmileIDSampleTestIds.newProfilePhone
      )
      UseSmileIDSampleButton(
        text: "Create profile",
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
    testId: String
  ) -> some View {
    UseSmileIDSampleTextInput(value: value, placeholder: placeholder, keyboardType: keyboardType, testId: testId) {
      UseSmileIDSampleIcon(icon, tint: colors.input.placeholder, size: iconSize)
    }
  }
}
