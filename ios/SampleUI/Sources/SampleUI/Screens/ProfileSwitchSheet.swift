import SwiftUI

/// The profile-switch sheet. Selecting one switches immediately, which is why it needs no save action.
public struct ProfileSwitchSheet: View {
  private let profiles: [UseSmileIDSampleProfile]
  private let activeId: String?
  private let onSelect: (UseSmileIDSampleProfile) -> Void
  private let onCreate: (() -> Void)?

  /// A nil `onCreate` hides the "New profile" row, for a host that offers no way to create one.
  public init(
    profiles: [UseSmileIDSampleProfile],
    activeId: String?,
    onSelect: @escaping (UseSmileIDSampleProfile) -> Void,
    onCreate: (() -> Void)? = nil
  ) {
    self.profiles = profiles
    self.activeId = activeId
    self.onSelect = onSelect
    self.onCreate = onCreate
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Switch profile", testId: UseSmileIDSampleTestIds.profileSwitchSheet) {
      ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
        UseSmileIDSampleProfileRow(
          organisation: profile.title,
          supportingText: profile.caption,
          initials: profile.initials,
          selected: profile.id == activeId,
          avatarColor: useSmileIDSampleAvatarColor(profileIndex: index),
          testId: UseSmileIDSampleTestIds.profileRow(profile.id),
          onTap: { onSelect(profile) }
        )
      }
      if let onCreate {
        UseSmileIDSampleProfileRow(
          organisation: "New profile",
          supportingText: "Run jobs as someone else",
          initials: "",
          selected: false,
          testId: UseSmileIDSampleTestIds.profileSwitchNew,
          onTap: onCreate
        )
      }
    }
  }
}
