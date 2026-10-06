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
public var useSmileIDSampleNavRows: [UseSmileIDSampleNavRow] {
  aboutRows + legalRows
}

private var aboutRows: [UseSmileIDSampleNavRow] {
  [
    .init(
      id: "documentation",
      title: UseSmileIDSampleStrings.settingsDocumentation,
      supportingText: "docs.usesmileid.com",
      icon: SmileIcons.docs,
      url: URL(string: "https://docs.usesmileid.com/"),
      opensInApp: true
    ),
    .init(
      id: "support",
      title: UseSmileIDSampleStrings.settingsSupport,
      supportingText: UseSmileIDSampleStrings.settingsSupportBody,
      icon: SmileIcons.support,
      url: URL(string: "https://smile.id/contact-us"),
      opensInApp: true
    )
  ]
}

private var legalRows: [UseSmileIDSampleNavRow] {
  [
    .init(
      id: "terms",
      title: UseSmileIDSampleStrings.settingsTerms,
      supportingText: nil,
      icon: SmileIcons.terms,
      url: URL(string: "https://smile.id/terms-and-conditions"),
      opensInApp: false
    ),
    .init(
      id: "privacy",
      title: UseSmileIDSampleStrings.settingsPrivacy,
      supportingText: nil,
      icon: SmileIcons.privacy,
      url: URL(string: "https://smile.id/privacy-policy"),
      opensInApp: false
    ),
    // No url: Apache-2.0 §4 asks the notice to travel with the distribution, so it is a screen here.
    .init(id: "licenses", title: UseSmileIDSampleStrings.settingsLicenses, supportingText: nil, icon: SmileIcons.licenses, url: nil, opensInApp: true)
  ]
}

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
  /// The device's own theme, which the System label names; the shell reads it where the app's choice cannot mask it.
  public var deviceDark: Bool
  /// The device's languages, which the System label resolves.
  public var deviceLanguages: [String]
  /// The language the process started with, which the row names until the next launch.
  public var runningLanguage: UseSmileIDSampleLanguage?

  public init(
    settings: UseSmileIDSampleSettings,
    organisation: String,
    initials: String,
    versionLabel: String,
    consentBoundByToken: Bool = false,
    avatarColor: Color = smileProfileHues[0],
    hasProfile: Bool = true,
    deviceDark: Bool,
    deviceLanguages: [String] = [],
    runningLanguage: UseSmileIDSampleLanguage? = nil
  ) {
    self.settings = settings
    self.organisation = organisation
    self.initials = initials
    self.versionLabel = versionLabel
    self.consentBoundByToken = consentBoundByToken
    self.avatarColor = avatarColor
    self.hasProfile = hasProfile
    self.deviceDark = deviceDark
    self.deviceLanguages = deviceLanguages
    self.runningLanguage = runningLanguage
  }
}

/// Settings, which every other screen's configuration comes from.
public struct SettingsScreen: View {
  private let state: UseSmileIDSampleSettingsState
  private let onSettingChange: (UseSmileIDSampleSetting, Bool) -> Void
  private let onProfile: () -> Void
  private let onNavRow: (UseSmileIDSampleNavRow) -> Void
  private let onCaptureMode: () -> Void
  private let onAppearance: () -> Void
  private let onLanguage: () -> Void
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
    onCaptureMode: @escaping () -> Void = {},
    onAppearance: @escaping () -> Void = {},
    onLanguage: @escaping () -> Void = {},
    onOpenScenarioDrawer: (() -> Void)? = nil,
    onSignOut: @escaping () -> Void
  ) {
    self.state = state
    self.onSettingChange = onSettingChange
    self.onProfile = onProfile
    self.onNavRow = onNavRow
    self.onCaptureMode = onCaptureMode
    self.onAppearance = onAppearance
    self.onLanguage = onLanguage
    self.onOpenScenarioDrawer = onOpenScenarioDrawer
    self.onSignOut = onSignOut
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
        UseSmileIDSampleText(UseSmileIDSampleStrings.settingsTitle, style: UseSmileIDSampleTheme.type.textStyleHeadingPage)
          .foregroundColor(colors.textTitle)
          .padding(.vertical, SmileSpacing.spacingXs)

        profileSection
        captureSection
        appearanceSection
        languageSection
        sdkScreensSection
        documentCaptureSection
        debugSection
        navSection(UseSmileIDSampleStrings.settingsSectionAbout, rows: aboutRows)
        navSection(UseSmileIDSampleStrings.settingsSectionLegal, rows: legalRows)

        UseSmileIDSampleDestructiveRow(text: UseSmileIDSampleStrings.settingsSignOut, testId: UseSmileIDSampleTestIds.signOut) {
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
    .useSmileIDSampleConfirmation(
      isPresented: $confirmingSignOut,
      title: UseSmileIDSampleStrings.settingsSignOutTitle,
      message: UseSmileIDSampleStrings.settingsSignOutBody,
      confirmLabel: UseSmileIDSampleStrings.settingsSignOut,
      confirmTestId: UseSmileIDSampleTestIds.signOutConfirm,
      onConfirm: onSignOut
    )
  }

  private var profileSection: some View {
    UseSmileIDSampleSectionSurface(label: UseSmileIDSampleStrings.settingsSectionProfile) {
      UseSmileIDSampleProfileRow(
        organisation: state.organisation,
        supportingText: state.hasProfile ? UseSmileIDSampleStrings.settingsProfileConfigure : UseSmileIDSampleStrings.settingsProfileCreate,
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
    UseSmileIDSampleSectionSurface(label: UseSmileIDSampleStrings.settingsSectionCapture) {
      switchRow(
        title: Self.enhancedSmartSelfieTitle,
        icon: SmileIcons.smile,
        supporting: state.settings.agentMode ? UseSmileIDSampleStrings.settingsEnhancedSmartSelfieMutex : UseSmileIDSampleStrings.settingsEnhancedSmartSelfieBody,
        setting: .enhancedSmartSelfie,
        testId: UseSmileIDSampleTestIds.settingEnhancedSmartSelfie
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: UseSmileIDSampleStrings.settingsAgentMode,
        icon: SmileIcons.agent,
        supporting: state.settings.enhancedSmartSelfie
          ? UseSmileIDSampleStrings.settingsAgentModeMutex(setting: UseSmileIDSampleStrings.settingsEnhancedSmartSelfie)
          : UseSmileIDSampleStrings.settingsAgentModeBody,
        setting: .agentMode,
        testId: UseSmileIDSampleTestIds.settingAgentMode
      )
    }
  }

  private var languageSection: some View {
    UseSmileIDSampleSectionSurface(label: UseSmileIDSampleStrings.settingsSectionLanguage) {
      UseSmileIDSampleSettingRow(
        title: UseSmileIDSampleStrings.settingsLanguage,
        supportingText: (state.runningLanguage ?? state.settings.language).label(deviceLanguages: state.deviceLanguages),
        testId: UseSmileIDSampleTestIds.settingLanguage,
        onTap: onLanguage
      ) {
        UseSmileIDSampleIcon(SmileIcons.settingLanguage, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
      } trailing: {
        UseSmileIDSampleSettingRowChevron()
      }
    }
  }

  private var appearanceSection: some View {
    UseSmileIDSampleSectionSurface(label: UseSmileIDSampleStrings.settingsSectionAppearance) {
      UseSmileIDSampleSettingRow(
        title: UseSmileIDSampleStrings.settingsTheme,
        supportingText: state.settings.appearance.label(deviceDark: state.deviceDark),
        testId: UseSmileIDSampleTestIds.settingAppearance,
        onTap: onAppearance
      ) {
        UseSmileIDSampleIcon(SmileIcons.darkMode, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
      } trailing: {
        UseSmileIDSampleSettingRowChevron()
      }
    }
  }

  private var sdkScreensSection: some View {
    UseSmileIDSampleSectionSurface(label: UseSmileIDSampleStrings.settingsSectionSdkScreens) {
      switchRow(
        title: UseSmileIDSampleStrings.settingsConsent,
        icon: SmileIcons.consent,
        supporting: state.consentBoundByToken
          ? UseSmileIDSampleStrings.settingsConsentBound
          : UseSmileIDSampleStrings.settingsConsentBody,
        setting: .consentStep,
        testId: UseSmileIDSampleTestIds.settingConsentStep,
        enabled: !state.consentBoundByToken
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: UseSmileIDSampleStrings.settingsInstructions,
        icon: SmileIcons.instructions,
        supporting: UseSmileIDSampleStrings.settingsInstructionsBody,
        setting: .instructionsStep,
        testId: UseSmileIDSampleTestIds.settingInstructionsStep
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: UseSmileIDSampleStrings.settingsPreview,
        icon: SmileIcons.preview,
        supporting: UseSmileIDSampleStrings.settingsPreviewBody,
        setting: .previewStep,
        testId: UseSmileIDSampleTestIds.settingPreviewStep
      )
    }
  }

  /// The design draws no such section either; it sits with the other capture choices.
  private var documentCaptureSection: some View {
    UseSmileIDSampleSectionSurface(label: UseSmileIDSampleStrings.settingsSectionDocumentCapture) {
      UseSmileIDSampleSettingRow(
        title: UseSmileIDSampleStrings.settingsCaptureMode,
        supportingText: state.settings.captureMode.label,
        testId: UseSmileIDSampleTestIds.settingCaptureMode,
        onTap: onCaptureMode
      ) {
        UseSmileIDSampleIcon(SmileIcons.documentVerification, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
      } trailing: {
        UseSmileIDSampleSettingRowChevron()
      }
      UseSmileIDSampleRowDivider()
      switchRow(
        title: UseSmileIDSampleStrings.settingsGalleryUpload,
        icon: SmileIcons.preview,
        supporting: UseSmileIDSampleStrings.settingsGalleryUploadBody,
        setting: .galleryUpload,
        testId: UseSmileIDSampleTestIds.settingGalleryUpload
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: UseSmileIDSampleStrings.settingsSkipBack,
        icon: SmileIcons.instructions,
        supporting: UseSmileIDSampleStrings.settingsSkipBackBody,
        setting: .allowSkipBack,
        testId: UseSmileIDSampleTestIds.settingAllowSkipBack
      )
      UseSmileIDSampleRowDivider()
      switchRow(
        title: UseSmileIDSampleStrings.settingsSelfieFirst,
        icon: SmileIcons.smile,
        supporting: UseSmileIDSampleStrings.settingsSelfieFirstBody,
        setting: .selfieFirst,
        testId: UseSmileIDSampleTestIds.settingSelfieFirst
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

  private static var enhancedSmartSelfieTitle: String {
    UseSmileIDSampleStrings.settingsEnhancedSmartSelfie
  }
}
