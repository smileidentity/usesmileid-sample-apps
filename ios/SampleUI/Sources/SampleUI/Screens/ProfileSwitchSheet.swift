import SwiftUI

/// The profile-switch sheet. Selecting one switches immediately, which is why it needs no save action.
public struct ProfileSwitchSheet: View {
  private let profiles: [UseSmileIDSampleProfile]
  private let activeId: String
  private let onSelect: (UseSmileIDSampleProfile) -> Void

  public init(
    profiles: [UseSmileIDSampleProfile],
    activeId: String,
    onSelect: @escaping (UseSmileIDSampleProfile) -> Void
  ) {
    self.profiles = profiles
    self.activeId = activeId
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Switch profile", testId: UseSmileIDSampleTestIds.profileSwitchSheet) {
      ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
        UseSmileIDSampleProfileRow(
          organisation: profile.organisation,
          supportingText: profile.person,
          initials: profile.initials,
          selected: profile.id == activeId,
          avatarColor: useSmileIDSampleAvatarColor(profileIndex: index),
          testId: UseSmileIDSampleTestIds.profileRow(profile.id),
          onTap: { onSelect(profile) }
        )
      }
    }
  }
}
