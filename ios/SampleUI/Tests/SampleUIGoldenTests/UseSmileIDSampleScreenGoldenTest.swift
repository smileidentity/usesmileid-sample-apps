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

  func testProductsSessionEnded() {
    goldens("products_session_ended") { products(.init(initials: "KB", sessionEnded: true)) }
  }

  /// The compact result line, which only a run in flight puts above the grid.
  func testProductsInFlight() {
    goldens("products_in_flight") {
      products(.init(initials: "KB", result: UseSmileIDSampleResultFixtures.running))
    }
  }

  /// Fixed by the harness, not by the design: a screen scrolls, so its frame is pinned here and its
  /// content grows inside it rather than making the frame taller.
  func testProductsSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) {
      products(.init(initials: "KB", sessionId: "a41f", sessionRemaining: "07:12"))
    }
  }

  func testSettings() {
    goldens("settings") { settings(UseSmileIDSampleSettings()) }
  }

  /// Agent mode on: the capture pair is mutually exclusive, so both supporting lines change.
  func testSettingsAgentMode() {
    goldens("settings_agent_mode") {
      settings(UseSmileIDSampleSettings(enhancedSmartSelfie: false, agentMode: true), consentBound: true)
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
    goldens("verification_details_processing") { details(Self.fixture(.processing, index: 1)) }
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
    CountryPickerSheet(selected: .kenya, query: .constant(query), onSelect: { _ in })
      .frame(height: height)
  }

  private func idTypePicker(country: UseSmileIDSampleCountry?, height: CGFloat = 700) -> some View {
    IdTypePickerSheet(country: country, selected: .passport, query: .constant(""), onSelect: { _ in })
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

  /// The store's own rows, until the store lands.
  private static func fixture(_ status: UseSmileIDSampleStatus, index: Int) -> UseSmileIDSampleJob {
    let products = UseSmileIDSampleProduct.allCases
    return UseSmileIDSampleJob(
      id: String(format: "job_%02dky31za%02d", index, index * 7 % 100),
      userId: String(format: "user_%02dky31za%02d", index, index * 3 % 100),
      product: products[index % products.count],
      status: status,
      createdAt: Self.fixedNow.addingTimeInterval(TimeInterval(-index * 5 * 60 * 60)),
      message: Self.message(status),
      httpStatus: status == .processing ? 202 : 200
    )
  }

  private static func message(_ status: UseSmileIDSampleStatus) -> String {
    switch status {
    case .clear: "Approved"
    case .attention: "Provisional \u{2014} needs review"
    case .blocked: "Rejected"
    case .processing: "Submitted, awaiting result"
    }
  }

  /// 2026-07-16T11:50:12Z, the instant the design's rows are dated from.
  private static let fixedNow = Date(timeIntervalSince1970: 1784202612)

  private func products(_ state: UseSmileIDSampleProductsState) -> some View {
    ProductsScreen(state: state, onProduct: { _ in }, onProfile: {}, onScan: {})
      .frame(height: 900)
  }

  private func settings(_ values: UseSmileIDSampleSettings, consentBound: Bool = false) -> some View {
    SettingsScreen(
      state: .init(
        settings: values,
        organisation: "Kobo Bank",
        initials: "KB",
        versionLabel: "UseSmileID Sample 1.0 · SDK 12.0.2",
        consentBoundByToken: consentBound
      ),
      onSettingChange: { _, _ in },
      onProfile: {},
      onNavRow: { _ in },
      onOpenScenarioDrawer: {},
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

  func testScenarioDrawerSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { scenarioDrawer(height: 1400) }
  }

  private func scenarioDrawer(height: CGFloat = 700) -> some View {
    ScenarioDrawerSheet(
      activeScenario: .expiredToken,
      activeTheme: .brandDefault,
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

  func testScanTokenSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { scanToken(height: 1400) }
  }

  func testScanTokenRedirectedSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType(growsWithContentSize: false) { scanToken(reason: .sessionEnded, height: 1400) }
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
