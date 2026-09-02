import SwiftUI

/// What the profiles list draws, plus the created confirmation it owns because the sheet that causes
/// it is its layer.
public struct UseSmileIDSampleProfilesState: Equatable {
  public var profiles: [UseSmileIDSampleProfile]
  public var activeId: String
  public var notice: UseSmileIDSampleTransientNotice?

  public init(
    profiles: [UseSmileIDSampleProfile],
    activeId: String,
    notice: UseSmileIDSampleTransientNotice? = nil
  ) {
    self.profiles = profiles
    self.activeId = activeId
    self.notice = notice
  }
}

/// Every profile the app can act as. Tapping one configures it; switching happens on the sheet.
public struct ProfilesScreen: View {
  private let state: UseSmileIDSampleProfilesState
  private let onProfileTap: (UseSmileIDSampleProfile) -> Void
  private let onCreate: () -> Void
  private let onBack: () -> Void
  private let onNoticeAction: () -> Void
  private let onNoticeDismiss: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleProfilesState,
    onProfileTap: @escaping (UseSmileIDSampleProfile) -> Void,
    onCreate: @escaping () -> Void,
    onBack: @escaping () -> Void,
    onNoticeAction: @escaping () -> Void = {},
    onNoticeDismiss: @escaping () -> Void = {}
  ) {
    self.state = state
    self.onProfileTap = onProfileTap
    self.onCreate = onCreate
    self.onBack = onBack
    self.onNoticeAction = onNoticeAction
    self.onNoticeDismiss = onNoticeDismiss
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: "Profiles", onBack: onBack)
      ScrollView {
        VStack(spacing: SmileSpacing.spacingXs) {
          ForEach(Array(state.profiles.enumerated()), id: \.element.id) { index, profile in
            UseSmileIDSampleProfileRow(
              organisation: profile.organisation,
              supportingText: supportingText(profile),
              initials: profile.initials,
              selected: false,
              avatarColor: useSmileIDSampleAvatarColor(profileIndex: index),
              testId: UseSmileIDSampleTestIds.profileRow(profile.id),
              onTap: { onProfileTap(profile) }
            ) {
              UseSmileIDSampleSettingRowChevron()
            }
          }
          createRow
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.bottom, SmileSpacing.spacingMd)
      }
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.profilesScreen)
    }
    .background(colors.background)
    // The host already insets a pushed route past the system bar; insetting again lifts it into the list.
    .overlay(alignment: .bottom) {
      UseSmileIDSampleTransientNoticeHost(
        notice: state.notice,
        onAction: onNoticeAction,
        onDismiss: onNoticeDismiss
      )
      .padding(.horizontal, SmileSpacing.spacingMd)
      .padding(.vertical, SmileSpacing.spacingLg)
    }
  }

  private func supportingText(_ profile: UseSmileIDSampleProfile) -> String {
    profile.id == state.activeId ? profile.person + " \u{00B7} active" : profile.person
  }

  /// The last row: no card and no border, a pale primary tile with a plus.
  private var createRow: some View {
    UseSmileIDSampleCreateProfileRow(action: onCreate)
  }
}

private struct UseSmileIDSampleCreateProfileRow: View {
  let action: () -> Void

  @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    Button(action: action) {
      HStack(spacing: SmileSpacing.spacingSm) {
        RoundedRectangle(cornerRadius: Self.tileRadius, style: .continuous)
          .fill(colors.badge.infoBackground)
          .frame(width: tileSize, height: tileSize)
          .overlay(UseSmileIDSampleIcon(SmileIcons.plus, tint: colors.primary, size: SmileSpacing.sizeIconMd))
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          UseSmileIDSampleText(
            "Create new profile",
            style: UseSmileIDSampleTheme.type.textStyleBodyStrong.with(size: 14.5)
          )
          .foregroundColor(colors.textTitle)
          UseSmileIDSampleText(
            "Its user details will live under it",
            style: UseSmileIDSampleTheme.type.textStyleCaption
          )
          .foregroundColor(colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, Self.paddingX)
      .padding(.vertical, SmileSpacing.spacingSm)
    }
    .buttonStyle(.plain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.createProfile)
  }

  private static let tileRadius: CGFloat = 12
  private static let paddingX: CGFloat = 14
}
