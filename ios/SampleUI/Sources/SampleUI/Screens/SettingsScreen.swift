import SwiftUI

/// One ABOUT or LEGAL row: an id, a title, the line beneath it, and where it goes.
public struct UseSmileIDSampleNavRow: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let supportingText: String?
  public let icon: SmileIcon
  /// Opened externally. `nil` means the app handles the row itself, which only licences does.
  public let url: URL?
  /// False where the in-app browser cannot render it: both legal pages serve a PDF a browser shows as a stub.
  public let opensInApp: Bool

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

/// The rows in the order the design draws them, so a caller can assert the set rather than the screen.
public let useSmileIDSampleNavRows: [UseSmileIDSampleNavRow] = aboutRows + legalRows

private let aboutRows: [UseSmileIDSampleNavRow] = [
  .init(
    id: "documentation",
    title: "Documentation",
    supportingText: "docs.usesmileid.com",
    icon: SmileIcons.docs,
    url: URL(string: "https://docs.usesmileid.com/"),
    opensInApp: true
  ),
  .init(
    id: "support",
    title: "Support",
    supportingText: "Contact the Smile team",
    icon: SmileIcons.support,
    url: URL(string: "https://smile.id/contact-us"),
    opensInApp: true
  )
]

private let legalRows: [UseSmileIDSampleNavRow] = [
  .init(
    id: "terms",
    title: "Terms of Service",
    supportingText: nil,
    icon: SmileIcons.terms,
    url: URL(string: "https://smile.id/terms-and-conditions"),
    opensInApp: false
  ),
  .init(
    id: "privacy",
    title: "Privacy Policy",
    supportingText: nil,
    icon: SmileIcons.privacy,
    url: URL(string: "https://smile.id/privacy-policy"),
    opensInApp: false
  ),
  // No url: Apache-2.0 §4 asks the notice to travel with the distribution, so it is a screen here.
  .init(id: "licenses", title: "Open-source licenses", supportingText: nil, icon: SmileIcons.licenses, url: nil, opensInApp: true)
]

/// Everything the settings list renders; callbacks stay parameters, like every screen.
public struct UseSmileIDSampleSettingsState: Equatable {
  public var settings: UseSmileIDSampleSettings
  public var organisation: String
  public var initials: String
  /// Passed in because it names the host, and this module runs under eight.
  public var versionLabel: String
  /// The token has taken the consent decision away, so the switch stops claiming to own it.
  public var consentBoundByToken: Bool
  public var avatarColor: Color
  /// False while there is no profile, when the card invites creating one.
  public var hasProfile: Bool

  public init(
    settings: UseSmileIDSampleSettings,
    organisation: String,
    initials: String,
    versionLabel: String,
    consentBoundByToken: Bool = false,
    avatarColor: Color = smileProfileHues[0],
    hasProfile: Bool = true
  ) {
    self.settings = settings
    self.organisation = organisation
    self.initials = initials
    self.versionLabel = versionLabel
    self.consentBoundByToken = consentBoundByToken
    self.avatarColor = avatarColor
    self.hasProfile = hasProfile
  }
}

/// Settings, which every other screen's configuration comes from.
public struct SettingsScreen: View {
  private let state: UseSmileIDSampleSettingsState
  private let onSettingChange: (UseSmileIDSampleSetting, Bool) -> Void
  private let onProfile: () -> Void
  private let onNavRow: (UseSmileIDSampleNavRow) -> Void
  /// `nil` hides the DEBUG section: `sample-ui` may not read a host's build configuration.
  private let onOpenScenarioDrawer: (() -> Void)?
  private let onSignOut: () -> Void

  @State private var confirmingSignOut = false
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleSettingsState,
    onSettingChange: @escaping (UseSmileIDSampleSetting, Bool) -> Void,
    onProfile: @escaping () -> Void,
    onNavRow: @escaping (UseSmileIDSampleNavRow) -> Void,
    onOpenScenarioDrawer: (() -> Void)? = nil,
    onSignOut: @escaping () -> Void
  ) {
    self.state = state
    self.onSettingChange = onSettingChange
    self.onProfile = onProfile
    self.onNavRow = onNavRow
    self.onOpenScenarioDrawer = onOpenScenarioDrawer
    self.onSignOut = onSignOut
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
        UseSmileIDSampleText("Settings", style: UseSmileIDSampleTheme.type.textStyleHeadingPage)
          .foregroundColor(colors.textTitle)
          .padding(.vertical, SmileSpacing.spacingXs)

        profileSection
        captureSection
        appearanceSection
        sdkScreensSection
        debugSection
        navSection("ABOUT", rows: aboutRows)
        navSection("LEGAL", rows: legalRows)

        UseSmileIDSampleDestructiveRow(text: "Sign out", testId: UseSmileIDSampleTestIds.signOut) {
          confirmingSignOut = true
        }

        UseSmileIDSampleText(state.versionLabel, style: UseSmileIDSampleTheme.type.textStyleCaption)
          .foregroundColor(colors.textMuted)
          .frame(maxWidth: .infinity)
          .padding(SmileSpacing.spacingMd)
          .useSmileIDSampleTestId(UseSmileIDSampleTestIds.versionLabel)
      }
      .padding(.horizontal, SmileSpacing.spacingMd)
    }
    .background(colors.background)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.settingsScreen)
    // Asked first: signing out deletes every profile, which a stray tap must not cost anyone.
    .useSmileIDSampleConfirmation(
      isPresented: $confirmingSignOut,
      title: "Sign out?",
      message: "This ends the token session and deletes every profile on this device.",
      confirmLabel: "Sign out",
      confirmTestId: UseSmileIDSampleTestIds.signOutConfirm,
      onConfirm: onSignOut
    )
  }

  private var profileSection: some View {
    UseSmileIDSampleSectionSurface(label: "PROFILE") {
      UseSmileIDSampleProfileRow(
        organisation: state.organisation,
        supportingText: state.hasProfile ? "Tap to configure" : "Tap to create one",
        initials: state.initials,
        selected: false,
        avatarColor: state.avatarColor,
        testId: UseSmileIDSampleTestIds.profileSummary,
        onTap: onProfile
      ) {
        UseSmileIDSampleSettingRowChevron()
      }
    }
  }

  /// Mutually exclusive, so each row says what turning it on does to the other.
  private var captureSection: some View {
    UseSmileIDSampleSectionSurface(label: "CAPTURE") {
      switchRow(
        title: Self.enhancedSmartSelfieTitle,
        icon: SmileIcons.smile,
        supporting: state.settings.agentMode ? "Turns Agent mode off" : "Face capture uses head-turns",
        setting: .enhancedSmartSelfie,
        testId: UseSmileIDSampleTestIds.settingEnhancedSmartSelfie
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: "Agent mode",
        icon: SmileIcons.agent,
        supporting: state.settings.enhancedSmartSelfie
          ? "Turns \(Self.enhancedSmartSelfieTitle) off"
          : "Operator captures for the applicant",
        setting: .agentMode,
        testId: UseSmileIDSampleTestIds.settingAgentMode
      )
    }
  }

  private var appearanceSection: some View {
    UseSmileIDSampleSectionSurface(label: "APPEARANCE") {
      switchRow(
        title: "Dark mode",
        icon: SmileIcons.darkMode,
        supporting: "Switch appearance",
        setting: .darkMode,
        testId: UseSmileIDSampleTestIds.settingDarkMode
      )
    }
  }

  private var sdkScreensSection: some View {
    UseSmileIDSampleSectionSurface(label: "SDK SCREENS — SHOW OR SKIP FLOW STEPS") {
      switchRow(
        title: "Consent screen",
        icon: SmileIcons.consent,
        supporting: state.consentBoundByToken
          ? "The token grants consent, so the screen is skipped"
          : "Ask permission before KYC checks",
        setting: .consentStep,
        testId: UseSmileIDSampleTestIds.settingConsentStep,
        enabled: !state.consentBoundByToken
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: "Instruction screen",
        icon: SmileIcons.instructions,
        supporting: "Prep tips before capture",
        setting: .instructionsStep,
        testId: UseSmileIDSampleTestIds.settingInstructionsStep
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: "Preview screen",
        icon: SmileIcons.preview,
        supporting: "Confirm or retake after capture",
        setting: .previewStep,
        testId: UseSmileIDSampleTestIds.settingPreviewStep
      )
    }
  }

  /// The design draws no control for the drawer, so this placement is ours, and debug-only.
  @ViewBuilder
  private var debugSection: some View {
    if let onOpenScenarioDrawer {
      UseSmileIDSampleSectionSurface(label: "DEBUG") {
        UseSmileIDSampleSettingRow(
          title: "Scenarios",
          supportingText: "Choose how the environment misbehaves",
          testId: UseSmileIDSampleTestIds.scenarioDrawerButton,
          onTap: onOpenScenarioDrawer
        ) {
          UseSmileIDSampleIcon(SmileIcons.settingScenarios, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
        } trailing: {
          UseSmileIDSampleSettingRowChevron()
        }
      }
    }
  }

  private func navSection(_ label: String, rows: [UseSmileIDSampleNavRow]) -> some View {
    UseSmileIDSampleSectionSurface(label: label) {
      ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
        if index > 0 {
          UseSmileIDSampleRowDivider()
        }
        UseSmileIDSampleSettingRow(
          title: row.title,
          supportingText: row.supportingText,
          testId: UseSmileIDSampleTestIds.navRow(row.id),
          onTap: { onNavRow(row) }
        ) {
          UseSmileIDSampleIcon(row.icon, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
        } trailing: {
          UseSmileIDSampleSettingRowChevron()
        }
      }
    }
  }

  private func switchRow(
    title: String,
    icon: SmileIcon,
    supporting: String,
    setting: UseSmileIDSampleSetting,
    testId: String,
    enabled: Bool = true
  ) -> some View {
    // Both closures labelled: with no onTap to take it, an unlabelled one binds there and the glyph vanishes.
    UseSmileIDSampleSettingRow(
      title: title,
      supportingText: supporting,
      leading: { UseSmileIDSampleIcon(icon, tint: colors.textTitle, size: SmileSpacing.sizeIconMd) },
      trailing: {
        UseSmileIDSampleSwitch(
          isOn: Binding(
            get: { state.settings[setting] },
            set: { onSettingChange(setting, $0) }
          ),
          enabled: enabled,
          testId: testId
        )
      }
    )
  }

  private static let enhancedSmartSelfieTitle = "Enhanced SmartSelfie\u{2122}"
}
