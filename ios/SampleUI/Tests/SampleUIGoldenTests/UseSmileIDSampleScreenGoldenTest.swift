@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleScreenGoldenTest: UseSmileIDSampleGoldenTest {
  func testProductsNoSession() {
    goldens("products_no_session") { products(.init(initials: "KB")) }
  }

  func testProductsActiveSession() {
    goldens("products_active_session") {
      products(.init(initials: "KB", sessionId: "a41f", sessionRemaining: "07:12"))
    }
  }

  /// The same card late in the span: the spec's state is the number, the frame having only one card.
  func testProductsSessionLate() {
    goldens("products_session_late") {
      products(.init(initials: "KB", sessionId: "a41f", sessionRemaining: "01:40"))
    }
  }

  func testProductsSessionEnded() {
    goldens("products_session_ended") { products(.init(initials: "KB", sessionEnded: true)) }
  }

  /// The compact result line, which only a run in flight puts above the grid.
  func testProductsInFlight() {
    goldens("products_in_flight") {
      products(.init(initials: "KB", result: UseSmileIDSampleResultFixtures.running))
    }
  }

  /// Fixed by the harness: a screen scrolls, so its frame is pinned and the content grows inside it.
  func testProductsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      products(.init(initials: "KB", sessionId: "a41f", sessionRemaining: "07:12"))
    }
  }

  /// The partner's screen: no DEBUG section, which is the only state the design draws.
  func testSettings() {
    goldens("settings") { settings(UseSmileIDSampleSettings()) }
  }

  func testSettingsDebugBuild() {
    goldens("settings_debug") { settings(UseSmileIDSampleSettings(), debug: true) }
  }

  /// Agent mode on: the capture pair is mutually exclusive, so both supporting lines change.
  func testSettingsAgentMode() {
    goldens("settings_agent_mode") {
      settings(UseSmileIDSampleSettings(enhancedSmartSelfie: false, agentMode: true), consentBound: true)
    }
  }

  /// A second seeded profile active: the PROFILE row is the only thing the frame changes.
  func testSettingsAltProfile() {
    goldens("settings_alt_profile") {
      settings(UseSmileIDSampleSettings(), profile: Self.seededProfiles.all[1], profileIndex: 1)
    }
  }

  /// Straight out of the new-profile sheet, so the row carries the created organisation's own hue.
  func testSettingsNewlyCreatedProfile() {
    goldens("settings_new_profile") {
      settings(UseSmileIDSampleSettings(), profile: Self.profilesWithACreatedOne.all[3], profileIndex: 3)
    }
  }

  func testSettingsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { settings(UseSmileIDSampleSettings()) }
  }

  func testVerificationDetailsClear() {
    goldens("verification_details_clear") { details(Self.fixture(.clear, index: 0)) }
  }

  func testVerificationDetailsAttention() {
    goldens("verification_details_attention") { details(Self.fixture(.attention, index: 3)) }
  }

  func testVerificationDetailsBlocked() {
    goldens("verification_details_blocked") { details(Self.fixture(.blocked, index: 4)) }
  }

  func testVerificationDetailsProcessing() {
    goldens("verification_details_processing") { details(Self.processing) }
  }

  func testVerificationDetailsUnknownJob() {
    goldens("verification_details_unknown") {
      VerificationDetailsScreen(
        state: .init(jobId: "job_missing", result: UseSmileIDSampleResultFixtures.failed),
        resultExpanded: .constant(true),
        onBack: {},
        onDelete: {},
        onCopy: { _, _ in }
      )
      .frame(height: 560)
    }
  }

  /// A taller viewport: at the largest content size the rows fill 1800pt and the card sits below them.
  func testVerificationDetailsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      details(Self.fixture(.processing, index: 1), height: 3400)
    }
  }

  func testUserDetailsEmpty() {
    goldens("user_details_empty") { userDetails(UseSmileIDSampleUserDetails()) }
  }

  /// Mid-entry. The caret is the first responder's, which an unhosted render has none of.
  func testUserDetailsEditing() {
    goldens("user_details_editing") { userDetails(Self.partialDetails) }
  }

  func testUserDetailsComplete() {
    goldens("user_details_complete") { userDetails(Self.completeDetails) }
  }

  /// A token binding both names and no contact — the partial case the form has to explain.
  func testUserDetailsTokenSuppliedNames() {
    goldens("user_details_token_supplied") {
      userDetails(UseSmileIDSampleUserDetails(), requirement: .init(firstName: false, lastName: false))
    }
  }

  func testUserDetailsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      userDetails(Self.completeDetails, height: 1400)
    }
  }

  func testUserDetailsTokenSuppliedSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      userDetails(
        UseSmileIDSampleUserDetails(),
        requirement: .init(firstName: false, lastName: false),
        height: 1400
      )
    }
  }

  private func userDetails(
    _ details: UseSmileIDSampleUserDetails,
    requirement: UseSmileIDSampleUserDetailsRequirement = .init(),
    height: CGFloat = 700
  ) -> some View {
    UserDetailsScreen(
      state: .init(
        productLabel: "Biometric KYC",
        details: details,
        rememberDetails: true,
        requirement: requirement
      ),
      onFieldChange: { _, _ in },
      onRememberChange: { _ in },
      onBack: {},
      onContinue: {}
    )
    .frame(height: height)
  }

  private static let completeDetails = UseSmileIDSampleUserDetails(
    firstName: "Kwame",
    lastName: "Asante",
    email: "kwame@uptech.example",
    phone: "+254 700 000 000"
  )

  private static let partialDetails = UseSmileIDSampleUserDetails(firstName: "Kwa")

  func testKycFormEmpty() {
    goldens("kyc_form_empty") { kycForm(UseSmileIDSampleIdDetails()) }
  }

  func testKycFormSelected() {
    goldens("kyc_form_selected") { kycForm(Self.selectedId) }
  }

  func testKycFormSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { kycForm(Self.selectedId, height: 1400) }
  }

  func testCountryPicker() {
    goldens("country_picker") { countryPicker(query: "") }
  }

  func testCountryPickerNoMatch() {
    goldens("country_picker_no_match") { countryPicker(query: "Atlantis") }
  }

  func testIdTypePicker() {
    goldens("idtype_picker") { idTypePicker(country: .ghana) }
  }

  /// The trigger is disabled without a country, but a deep link can still open the sheet.
  func testIdTypePickerWithoutACountry() {
    goldens("idtype_picker_no_country") { idTypePicker(country: nil) }
  }

  func testCountryPickerSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { countryPicker(query: "", height: 1400) }
  }

  private func kycForm(_ details: UseSmileIDSampleIdDetails, height: CGFloat = 700) -> some View {
    KycIdFormScreen(
      state: .init(productLabel: "Biometric KYC", details: details),
      onCountryTap: {},
      onIdTypeTap: {},
      onIdNumberChange: { _ in },
      onBack: {},
      onContinue: {},
      onToken: {}
    )
    .frame(height: height)
  }

  private func countryPicker(query: String, height: CGFloat = 700) -> some View {
    CountryPickerSheet(selected: .kenya, query: .constant(query), onSelect: { _ in }, onClose: {})
      .frame(height: height)
  }

  private func idTypePicker(country: UseSmileIDSampleCountry?, height: CGFloat = 700) -> some View {
    IdTypePickerSheet(country: country, selected: .passport, query: .constant(""), onSelect: { _ in }, onClose: {})
      .frame(height: height)
  }

  private static let selectedId = UseSmileIDSampleIdDetails(
    country: .kenya,
    idType: .nationalId,
    idNumber: "AO12345678"
  )

  /// The card sits under the details, so the four states need the room the design frame did not.
  private func details(_ job: UseSmileIDSampleJob, height: CGFloat = 900) -> some View {
    VerificationDetailsScreen(
      state: .init(jobId: job.id, job: job, result: UseSmileIDSampleResultFixtures.succeeded),
      resultExpanded: .constant(true),
      onBack: {},
      onDelete: {},
      onCopy: { _, _ in }
    )
    .frame(height: height)
  }

  /// The store's own rows, so a screen's golden and a device run show the same eleven.
  private static let fixtures = UseSmileIDSampleJobStore.fixtures(
    now: Date(timeIntervalSince1970: 1784202612)
  )

  private static func fixture(_ status: UseSmileIDSampleStatus, index: Int) -> UseSmileIDSampleJob {
    let job = fixtures[index]
    XCTAssertEqual(job.status, status, "fixture \(index) is no longer \(status.label)")
    return job
  }

  /// What a real 202 says: a message long enough to need a second line of its own column.
  private static var processing: UseSmileIDSampleJob {
    let job = fixture(.processing, index: 1)
    return UseSmileIDSampleJob(
      id: job.id,
      userId: job.userId,
      product: job.product,
      status: job.status,
      createdAt: job.createdAt,
      message: "Request accepted and queued for processing.",
      httpStatus: job.httpStatus,
      sandbox: job.sandbox,
      sessionId: job.sessionId,
      partnerId: job.partnerId
    )
  }

  func testVerifications() {
    goldens("verifications") { verifications() }
  }

  func testVerificationsFiltered() {
    goldens("verifications_filtered") { verifications(filter: .attention) }
  }

  func testVerificationsEmpty() {
    goldens("verifications_empty") { verifications(jobs: []) }
  }

  func testVerificationsFilterEmpty() {
    goldens("verifications_filter_empty") {
      verifications(jobs: Self.fixtures.filter { $0.status == .clear }, filter: .blocked)
    }
  }

  func testVerificationsSelectMode() {
    goldens("verifications_select") { verifications(selectMode: true) }
  }

  func testVerificationsItemsSelected() {
    goldens("verifications_selected") {
      verifications(selectMode: true, selected: Set(Self.fixtures.prefix(2).map(\.id)))
    }
  }

  /// Two rows gone and the confirmation that offers them back, which is the shell's bottom chrome.
  func testVerificationsAfterDelete() {
    goldens("verifications_after_delete") {
      VStack(spacing: SmileSpacing.spacingXs) {
        verifications(jobs: Array(Self.fixtures.dropFirst(2)), height: 800)
        UseSmileIDSampleTransientNoticeHost(notice: Self.removalNotice, onDismiss: {})
          .padding(.horizontal, SmileSpacing.spacingMd)
      }
    }
  }

  func testVerificationsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { verifications(height: 2200) }
  }

  /// The shell's copy, word for word: the rows are hidden from this app's list, not deleted.
  private static let removalNotice = UseSmileIDSampleTransientNotice(
    message: "2 verifications hidden from App list",
    actionLabel: "Undo"
  )

  private func verifications(
    jobs: [UseSmileIDSampleJob]? = nil,
    filter: UseSmileIDSampleJobFilter = .all,
    selectMode: Bool = false,
    selected: Set<String> = [],
    height: CGFloat = 900
  ) -> some View {
    let rows = jobs ?? Self.fixtures
    return VerificationsScreen(
      state: .init(
        jobs: rows,
        counts: Dictionary(
          uniqueKeysWithValues: UseSmileIDSampleJobFilter.allCases.map { ($0, rows.filter($0.matches).count) }
        ),
        filter: filter,
        selectMode: selectMode,
        selected: selected,
        today: useSmileIDSampleStartOfDay(Self.fixedNow, calendar: Self.utc),
        // Pinned, or the day headers and row times read in the recorder's own zone.
        calendar: Self.utc
      ),
      onFilterChange: { _ in },
      onSelectModeChange: { _ in },
      onSelectionChange: { _, _ in },
      onJobTap: { _ in },
      onRemove: { _ in }
    )
    .frame(height: height)
  }

  private static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }

  /// 2026-07-16T11:50:12Z, the instant the design's rows are dated from.
  private static let fixedNow = Date(timeIntervalSince1970: 1784202612)

  private func products(_ state: UseSmileIDSampleProductsState) -> some View {
    ProductsScreen(state: state, onProduct: { _ in }, onProfile: {}, onScan: {})
      .frame(height: 900)
  }

  private func settings(
    _ values: UseSmileIDSampleSettings,
    consentBound: Bool = false,
    profile: UseSmileIDSampleProfile? = nil,
    profileIndex: Int = 0,
    debug: Bool = false
  ) -> some View {
    SettingsScreen(
      state: .init(
        settings: values,
        organisation: profile?.organisation ?? "Kobo Bank",
        initials: profile?.initials ?? "KB",
        versionLabel: "UseSmileID Sample 1.0 · SDK 12.0.2",
        consentBoundByToken: consentBound,
        avatarColor: useSmileIDSampleAvatarColor(profileIndex: profileIndex)
      ),
      onSettingChange: { _, _ in },
      onProfile: {},
      onNavRow: { _ in },
      onOpenScenarioDrawer: debug ? {} : nil,
      onSignOut: {}
    )
    .frame(height: 1400)
  }

  func testProfiles() {
    goldens("profiles") { profiles(Self.seededProfiles) }
  }

  /// A plain launch: the one empty starter, its caption a placeholder until details are saved.
  func testProfilesFirstRun() {
    goldens("profiles_first_run") { profiles(UseSmileIDSampleProfiles()) }
  }

  /// The fourth profile is listed but not active: the confirmation carries the offer.
  func testProfilesCreated() {
    goldens("profiles_created") { profiles(Self.profilesWithACreatedOne, notice: Self.createdNotice) }
  }

  func testProfilesSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      profiles(Self.profilesWithACreatedOne, notice: Self.createdNotice, height: 1400)
    }
  }

  func testProfileConfigActiveProfile() {
    goldens("profile_config_active") { profileConfig(Self.seededProfiles.active, isActive: true) }
  }

  func testProfileConfigOtherProfile() {
    goldens("profile_config_other") { profileConfig(Self.seededProfiles.all[1]) }
  }

  /// Only the names came from the sheet, so the contact rows show their placeholders.
  func testProfileConfigNewlyCreated() {
    goldens("profile_config_new") { profileConfig(Self.profilesWithACreatedOne.all[3]) }
  }

  func testProfileConfigSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      profileConfig(Self.seededProfiles.active, isActive: true, height: 1400)
    }
  }

  func testProfileSwitch() {
    goldens("profile_switch") {
      ProfileSwitchSheet(profiles: Self.seededProfiles.all, activeId: "p-1", onSelect: { _ in })
        .frame(height: 700)
    }
  }

  func testNewProfileEmpty() {
    goldens("new_profile_empty") { newProfile(UseSmileIDSampleNewProfile()) }
  }

  func testNewProfileFilled() {
    goldens("new_profile_filled") { newProfile(Self.filledNewProfile) }
  }

  func testNewProfileSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { newProfile(Self.filledNewProfile, height: 1400) }
  }

  private func profiles(
    _ profiles: UseSmileIDSampleProfiles,
    notice: UseSmileIDSampleTransientNotice? = nil,
    height: CGFloat = 700
  ) -> some View {
    ProfilesScreen(
      state: .init(profiles: profiles.all, activeId: profiles.activeId, notice: notice),
      onProfileTap: { _ in },
      onCreate: {},
      onBack: {}
    )
    .frame(height: height)
  }

  private func profileConfig(
    _ profile: UseSmileIDSampleProfile,
    isActive: Bool = false,
    height: CGFloat = 700
  ) -> some View {
    ProfileConfigScreen(
      state: .init(organisation: profile.organisation, defaults: profile.defaults, isActive: isActive),
      onFieldChange: { _, _ in },
      onBack: {},
      onSave: {}
    )
    .frame(height: height)
  }

  private func newProfile(_ draft: UseSmileIDSampleNewProfile, height: CGFloat = 700) -> some View {
    NewProfileSheet(draft: .constant(draft), onSave: {})
      .frame(height: height)
  }

  private static let seededProfiles = UseSmileIDSampleProfiles(seed: UseSmileIDSampleProfiles.fixtures())

  func testScenarioDrawer() {
    goldens("scenario_drawer") { scenarioDrawer() }
  }

  /// One sheet holds both sections, so the two spec states differ by which selection has moved.
  func testScenarioDrawerThemeSelected() {
    goldens("scenario_drawer_theme") { scenarioDrawer(scenario: .normal, theme: .partnerOverride) }
  }

  func testScenarioDrawerSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { scenarioDrawer(height: 1400) }
  }

  private func scenarioDrawer(
    scenario: UseSmileIDSampleScenario = .expiredToken,
    theme: UseSmileIDSampleThemeScenario = .brandDefault,
    height: CGFloat = 700
  ) -> some View {
    ScenarioDrawerSheet(
      activeScenario: scenario,
      activeTheme: theme,
      onScenarioSelect: { _ in },
      onThemeSelect: { _ in }
    )
    .frame(height: height)
  }

  func testScanToken() {
    goldens("scan_token") { scanToken() }
  }

  /// The expiry gate's redirect: the caption is replaced by why the person was moved here.
  func testScanTokenRedirected() {
    goldens("scan_token_redirected") { scanToken(reason: .sessionEnded) }
  }

  /// 2400, not 1400: at 1400 the caption fell outside the viewport and both baselines matched.
  func testScanTokenSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { scanToken(height: 2400) }
  }

  func testScanTokenRedirectedSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { scanToken(reason: .sessionEnded, height: 2400) }
  }

  /// No viewfinder, as in every golden and every simulator run: the screen keeps the glyph.
  private func scanToken(reason: UseSmileIDSampleScanReason? = nil, height: CGFloat = 900) -> some View {
    ScanTokenScreen(
      entry: .constant(UseSmileIDSampleScanSheetState()),
      reason: reason,
      onBack: {},
      onLink: { _ in },
      onSimulate: { _, _, _ in },
      onPaste: { nil }
    )
    .frame(height: height)
  }

  func testLicenses() {
    goldens("licenses") { licenses(Self.notices) }
  }

  func testLicensesWithoutTheGeneratedAsset() {
    goldens("licenses_empty") { licenses(UseSmileIDSampleLicenses()) }
  }

  func testLicensesSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { licenses(Self.notices) }
  }

  private func licenses(_ notices: UseSmileIDSampleLicenses, height: CGFloat = 700) -> some View {
    LicensesScreen(licenses: notices, onBack: {})
      .frame(height: height)
  }

  /// Fixed rather than the bundled asset, so a dependency bump redraws no baseline; two rows carry no version.
  private static let notices = UseSmileIDSampleLicenses(components: [
    .init(
      component: "lottie-spm",
      version: "4.6.1",
      licenseId: "Apache-2.0",
      licenseName: "Apache License, Version 2.0",
      text: "Apache License\nVersion 2.0, January 2004"
    ),
    .init(
      component: "sentry-cocoa",
      version: "9.26.1",
      licenseId: "MIT",
      licenseName: "MIT License",
      text: "MIT License\n\nCopyright (c) 2015 Sentry"
    ),
    .init(
      component: "sentry-cocoa/KSCrash",
      version: "",
      licenseId: "MIT",
      licenseName: "MIT License",
      text: "MIT License\n\nCopyright (c) 2012 Karl Stenerud"
    ),
    .init(
      component: "sentry-cocoa/facebook/fishhook",
      version: "",
      licenseId: "BSD-3-Clause",
      licenseName: "BSD 3-Clause License",
      text: "Copyright (c) 2013, Facebook, Inc. All rights reserved."
    )
  ])

  private static let profilesWithACreatedOne: UseSmileIDSampleProfiles = {
    var profiles = UseSmileIDSampleProfiles(seed: UseSmileIDSampleProfiles.fixtures())
    profiles.add(
      organisation: "Acme Fintech",
      person: "Ada Lovelace",
      defaults: UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Lovelace")
    )
    return profiles
  }()

  private static let createdNotice = UseSmileIDSampleTransientNotice(
    message: "Acme Fintech created",
    actionLabel: "Make active"
  )

  private static let filledNewProfile = UseSmileIDSampleNewProfile(
    name: "Acme Fintech",
    firstName: "Ada",
    lastName: "Lovelace",
    email: "ada@acme.example",
    phone: "+254 700 000 000"
  )
}
