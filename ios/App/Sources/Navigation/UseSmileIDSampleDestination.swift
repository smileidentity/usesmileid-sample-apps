import Njia
import NjiaUI
import SampleUI
import SwiftUI

/// Binds a step of the graph to its screen; the mapping is the shell's because only it knows the graph.
struct UseSmileIDSampleDestination: View {
  let scope: UseSmileIDSampleStepScope

  @EnvironmentObject private var navigation: UseSmileIDSampleNavigationModel
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var inAppLink: UseSmileIDSampleInAppLink?
  /// The switch sheet's "New profile" swaps its content for the form, in the same sheet.
  @State private var creatingProfile = false

  private var navigator: NjiaNavigator {
    scope.navigator
  }

  private var engine: UseSmileIDSampleEngine {
    navigation.engine
  }

  /// The product of the run this step belongs to, read from the run's first entry.
  private var productId: String {
    engine.runProductId(scope.entry) ?? ""
  }

  private var product: UseSmileIDSampleProduct? {
    UseSmileIDSampleProduct(rawValue: productId)
  }

  var body: some View {
    switch scope.step.kind {
    case .products:
      ProductsScreen(
        state: .init(
          initials: app.initials,
          avatarColor: app.avatarColor,
          sessionId: app.sessionId,
          sessionRemaining: app.sessionRemaining,
          sessionEnded: app.sessionExpired,
          result: app.flowResult.snapshot
        ),
        onProduct: startRun,
        onProfile: { navigator.go(.profileSwitch) },
        onScan: { navigator.go(.scanToken) }
      )
      // Back on the grid means the run's form is gone, so a list still arriving for it is cancelled.
      .onAppear { app.catalogue.stop() }
    case .verifications:
      UseSmileIDSampleVerificationsHost(navigator: navigator)
    case .consentDetailsForm:
      UserDetailsScreen(
        state: .init(
          productLabel: product?.label ?? productId,
          details: app.userDetails,
          profile: app.profiles.active,
          profileIndex: app.profiles.activeIndex,
          saveToProfile: app.saveToProfile,
          organisation: app.organisationDraft,
          requirement: app.userDetailsRequirement(for: product)
        ),
        onFieldChange: { field, value in app.setUserField(field, to: value) },
        onSaveToProfileChange: { app.saveToProfile = $0 },
        onOrganisationChange: { app.organisationDraft = $0 },
        onProfileTap: { navigator.go(.profileSwitch) },
        onBack: navigator.back,
        // `next` from this entry only, so a second quick tap is stale and starts no second run.
        onContinue: {
          app.keepUserDetails(for: product)
          navigator.next()
        }
      )
      .navigationBarHidden(true)
      .onAppear {
        app.fillFormOnEntry()
        // A deep link to this form skips the product tap, so the lists start here if nothing has.
        app.ensureCatalogue(product)
      }
    case .authUserId:
      AuthUserIdScreen(
        userId: app.authUserId,
        // A user is enrolled under one partner in one environment, so another's IDs would authenticate nobody.
        previousUsers: useSmileIDSamplePreviousAuthUsers(
          app.jobs ?? [],
          partnerId: app.session?.partnerId,
          sandbox: app.useSandbox
        ),
        onUserIdChange: { app.authUserId = $0 },
        onRegister: registerInstead,
        onBack: navigator.back,
        onContinue: navigator.next
      )
      .navigationBarHidden(true)
    case .idDetailsForm:
      KycIdFormScreen(
        state: idFormState,
        onCountryTap: { navigator.go(.countryPicker) },
        onIdTypeTap: { navigator.go(.idTypePicker) },
        onDocumentTap: { navigator.go(.documentPicker) },
        onCaptureAsTap: { navigator.go(.captureAs) },
        onIdNumberChange: { app.idDetails.idNumber = $0 },
        onBack: navigator.back,
        onContinue: navigator.next,
        onToken: { navigator.go(.scanToken) }
      )
      .navigationBarHidden(true)
      .onAppear {
        app.ensureCatalogue(product)
        product.map { app.idDetails.keepDocumentListed(on: $0) }
        keepOnlyEnabled()
      }
      .onChange(of: app.session?.id) { _ in
        app.ensureCatalogue(product)
      }
      .onChange(of: enabledLists) { _ in
        keepOnlyEnabled()
      }
    case .countryPicker:
      CountryPickerSheet(
        catalogue: app.catalogue.countries(formFamily, product: pickerProduct),
        selected: app.idDetails.country,
        query: $app.countryQuery,
        onSelect: { app.selectCountry($0)
          navigator.back() },
        onRetry: { app.catalogue.retry() },
        onClose: navigator.back
      )
    case .idTypePicker:
      // Refused without a country, as its trigger is: a link can arrive before one is picked.
      if let country = app.idDetails.country {
        IdTypePickerSheet(
          country: country,
          catalogue: app.catalogue.idTypes(country.code),
          selected: app.idDetails.idType,
          query: $app.idTypeQuery,
          onSelect: { app.idDetails.idType = $0
            navigator.back() },
          onRetry: { app.catalogue.retry() },
          onClose: navigator.back
        )
      } else {
        Color.clear.onAppear(perform: navigator.back)
      }
    case .documentPicker:
      if let country = app.idDetails.country {
        DocumentPickerSheet(
          country: country,
          catalogue: app.catalogue.documents(country.code, product: pickerProduct),
          selected: app.idDetails.document,
          query: $app.documentQuery,
          onSelect: { app.idDetails.choose(document: $0)
            navigator.back() },
          onRetry: { app.catalogue.retry() },
          onClose: navigator.back
        )
      } else {
        Color.clear.onAppear(perform: navigator.back)
      }
    case .captureAs:
      if app.idDetails.document != nil {
        CaptureAsSheet(
          selected: app.idDetails.captureAsOverride,
          matched: useSmileIDSampleResolvedCaptureAs(
            document: app.idDetails.document,
            override: nil,
            genericDocument: app.idDetails.genericDocument
          )
        ) { choice in
          if choice == .genericDocument {
            // In this sheet's place, so closing the builder lands on the form.
            navigator.go(UseSmileIDSampleStep.genericDocument.rawValue, arg: nil, replace: scope.entry.id)
          } else {
            app.idDetails.captureAsOverride = choice
            navigator.back()
          }
        }
      } else {
        Color.clear.onAppear(perform: navigator.back)
      }
    case .genericDocument:
      GenericDocumentSheet(initial: app.idDetails.genericDocument) { genericDocument in
        app.idDetails.genericDocument = genericDocument
        app.idDetails.captureAsOverride = .genericDocument
        navigator.back()
      }
    case .verificationDetails:
      UseSmileIDSampleVerificationDetailsHost(jobId: scope.entry.arg ?? "", navigator: navigator)
        .navigationBarHidden(true)
    case .profiles:
      UseSmileIDSampleProfilesHost(navigator: navigator)
        .navigationBarHidden(true)
    case .profileConfig:
      if let profile = app.profiles.find(scope.entry.arg ?? "") {
        profileConfig(profile)
      } else {
        // Deleted, or never there: a link to a stale id leaves rather than drawing an empty form.
        Color.clear.onAppear(perform: navigator.back)
      }
    case .profileSwitch:
      if creatingProfile {
        newProfile
      } else {
        ProfileSwitchSheet(
          profiles: app.profiles.all,
          activeId: app.profiles.activeId,
          onSelect: { app.switchProfile(to: $0.id)
            navigator.back() },
          onCreate: {
            app.beginProfileFromSwitch()
            creatingProfile = true
          }
        )
      }
    case .newProfile:
      newProfile
    case .sdkFlow, .sdkFlowFullScreen:
      SdkFlowScreen(scope: scope)
    case .scanToken:
      UseSmileIDSampleScanTokenHost(scope: scope)
        .navigationBarHidden(true)
    case .settings:
      browser(SettingsScreen(
        state: .init(
          settings: app.settings,
          organisation: app.organisation,
          initials: app.initials,
          versionLabel: app.versionLabel,
          avatarColor: app.avatarColor,
          hasProfile: app.profiles.active != nil,
          deviceDark: app.deviceDark,
          deviceLanguages: app.deviceLanguages,
          runningLanguage: app.runningLanguage
        ),
        onSettingChange: { setting, enabled in app.change(setting, to: enabled) },
        onProfile: { navigator.go(.profiles) },
        onNavRow: { row in open(row) },
        onCaptureMode: { navigator.go(.captureMode) },
        onAppearance: { navigator.go(.appearance) },
        onLanguage: { navigator.go(.language) },
        // No launch argument reveals it: every flow reaches the drawer by deep link.
        onOpenScenarioDrawer: UseSmileIDSampleAppState.isDebugBuild ? { navigator.go(.scenarioDrawer) } : nil,
        debugRows: AnyView(UseSmileIDSampleDebugRows(extension: useSmileIDSampleShellExtension)),
        // There is no auth to leave; the session is the local state a partner would expect gone.
        onSignOut: { app.signOut()
          // The bar's own cross-tab switch, so the stack lands where selecting Products would.
          engine.leaveToProducts() }
      ))
    case .licenses:
      LicensesScreen(
        licenses: Self.notices,
        onBack: navigator.back,
        // Ejects, as the legal rows above it do; no shipped component takes this path today.
        onOpenUrl: { link in URL(string: link).map { UIApplication.shared.open($0) } }
      )
      .navigationBarHidden(true)
    case .captureMode:
      CaptureModeSheet(selected: app.settings.captureMode) { mode in
        app.setCaptureMode(mode)
        navigator.back()
      }
    case .appearance:
      AppearanceSheet(selected: app.settings.appearance, deviceDark: app.deviceDark) { appearance in
        app.setAppearance(appearance)
        navigator.back()
      }
    case .language:
      // Stays open after a pick, to say it applies at the next launch.
      LanguageSheet(
        selected: app.settings.language,
        deviceLanguages: app.deviceLanguages,
        pending: app.settings.language != app.runningLanguage
      ) { app.setLanguage($0) }
    case .scenarioDrawer:
      // App-level, not sheet-local: the result card reports the same selection.
      ScenarioDrawerSheet(
        activeScenario: app.flowResult.scenario,
        activeTheme: app.flowResult.theme,
        onScenarioSelect: { app.flowResult.selectScenario($0) },
        onThemeSelect: { app.flowResult.selectTheme($0) }
      )
    }
  }

  /// A product tap: the run's first form, or the scanner first when no live session backs it.
  private func startRun(_ product: UseSmileIDSampleProduct) {
    app.fillFormForRun(product)
    let run = app.entry(in: engine.graph, for: product)
    app.runPartnerId = run == nil ? nil : app.session?.partnerId
    if let run {
      engine.startRun(from: scope.entry, product: product, run: run)
    } else {
      navigator.go(.scanToken)
    }
  }

  /// SmartSelfie Registration in this run's place, for a user with no enrolment to authenticate.
  private func registerInstead() {
    app.fillFormForRun(.smartSelfieEnrollment)
    let start = engine.runStart(scope.entry)?.id
    if let run = app.entry(in: engine.graph, for: .smartSelfieEnrollment) {
      engine.startRun(from: scope.entry, product: .smartSelfieEnrollment, run: run, replace: start)
    } else {
      navigator.go(UseSmileIDSampleStep.scanToken.rawValue, arg: nil, replace: start)
    }
  }

  private var newProfile: some View {
    NewProfileSheet(
      draft: $app.newProfile,
      onSave: { app.createProfile()
        navigator.back() }
    )
  }

  private func profileConfig(_ profile: UseSmileIDSampleProfile) -> some View {
    let id = profile.id
    return ProfileConfigScreen(
      state: .init(
        title: profile.title,
        organisation: app.profileOrganisationDraft(for: id),
        defaults: app.profileDraft(for: id),
        isActive: id == app.profiles.activeId,
        changed: app.profileChanged(id),
        callbackUrl: app.profileCallbackDraft(for: id),
        callbackOverride: app.session?.callbackOverrideCaption
      ),
      onFieldChange: { field, value in app.editProfileDraft(id, field, to: value) },
      onOrganisationChange: { app.editProfileOrganisationDraft(id, to: $0) },
      onCallbackUrlChange: { value in app.editProfileCallbackDraft(id, to: value) },
      onBack: { app.discardProfileDraft(id)
        navigator.back() },
      onSave: { app.saveProfile(id)
        navigator.back() },
      onDelete: { navigator.back()
        app.deleteProfile(id) }
    )
    .navigationBarHidden(true)
  }

  /// The family of the form a picker layers over; a KYC form unless a document product's is on top.
  private var formFamily: UseSmileIDSampleCatalogueFamily {
    product?.catalogueFamily ?? .kyc
  }

  /// The product whose ID form the sheets sit on, so the document list can leave out what the SDK refuses on it.
  private var pickerProduct: UseSmileIDSampleProduct {
    product ?? .documentVerification
  }

  /// The form's state, with the chosen country's list deciding the second trigger's placeholder.
  private var idFormState: UseSmileIDSampleKycIdFormState {
    let family = product?.catalogueFamily ?? .kyc
    let loading: Bool = switch (app.idDetails.country?.code, family) {
    case (nil, _): false
    case (let code?, .kyc): app.catalogue.idTypes(code).isLoading
    case (let code?, .document): app.catalogue.documents(code, product: pickerProduct).isLoading
    case (_?, .passport): false
    }
    return .init(
      productLabel: product?.label ?? productId,
      family: family,
      details: app.idDetails,
      countryListLoading: loading
    )
  }

  /// Enhanced Document Verification's settled lists; nil for any other product or a list not yet settled.
  private var enabledLists: EnabledLists? {
    guard product == .enhancedDocumentVerification else { return nil }
    let countries = app.catalogue.countries(.document, product: .enhancedDocumentVerification).settledItems
    let documents = app.idDetails.country.flatMap { app.catalogue.documents($0.code, product: .enhancedDocumentVerification).settledItems }
    return EnabledLists(countries: countries, documents: documents)
  }

  private func keepOnlyEnabled() {
    guard let lists = enabledLists else { return }
    app.idDetails.keepOnlyEnabled(countries: lists.countries, documents: lists.documents)
  }

  private struct EnabledLists: Equatable {
    let countries: [UseSmileIDSampleCountry]?
    let documents: [UseSmileIDSampleDocument]?
  }

  /// Read once: the asset is generated into the binary, so it cannot change while the app runs.
  private static let notices = UseSmileIDSampleLicenses.bundled()

  /// A layer over the screen that opened it, never a step.
  private func browser(_ content: some View) -> some View {
    content.sheet(item: $inAppLink) { UseSmileIDSampleBrowser(url: $0.url) }
  }

  /// No url is this app's own screen, `opensInApp` stays in a sheet, and the legal pages eject because both serve a PDF.
  private func open(_ row: UseSmileIDSampleNavRow) {
    guard let url = row.url else {
      navigator.go(.licenses)
      return
    }
    if row.opensInApp {
      inAppLink = UseSmileIDSampleInAppLink(url: url)
    } else {
      UIApplication.shared.open(url)
    }
  }
}

/// One verification, the refresh it can ask for and the outcome that has to be said out loud.
private struct UseSmileIDSampleVerificationDetailsHost: View {
  let jobId: String
  let navigator: NjiaNavigator

  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var notice: UseSmileIDSampleTransientNotice?

  var body: some View {
    VerificationDetailsScreen(
      state: .init(
        jobId: jobId,
        job: app.jobs?.first { $0.id == jobId },
        result: app.flowResult.snapshot,
        showProbes: app.showProbes,
        pending: app.jobs == nil
      ),
      resultExpanded: $app.resultCardExpanded,
      onBack: navigator.back,
      // Hidden from this app's list, not deleted at the API: the store's own word for it.
      onDelete: { app.removeJobs([jobId])
        navigator.back() },
      onCopy: { label, value in copy(label, value) },
      onRefresh: { await refresh() }
    )
    // Asked again with the list's backoff while the server still has it processing, and afresh under a new session.
    .task(id: [jobId, app.session?.id ?? ""]) {
      // Off the store's first emission: nil is "not loaded yet", not "no row".
      guard await loaded(jobId)?.status == .processing else { return }
      // Silent unless something happened: "still processing" on every check is noise.
      guard let outcome = await app.refreshJobUntilSettled(jobId), outcome != .stillProcessing else { return }
      notice = UseSmileIDSampleTransientNotice(message: label(outcome))
    }
    .overlay(alignment: .bottom) {
      UseSmileIDSampleTransientNoticeHost(notice: notice, onDismiss: { notice = nil })
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.vertical, SmileSpacing.spacingLg)
    }
  }

  /// The row once the store has emitted at all; nil if the list arrives without it.
  private func loaded(_ jobId: String) async -> UseSmileIDSampleJob? {
    if let jobs = app.jobs {
      return jobs.first { $0.id == jobId }
    }
    for await jobs in app.$jobs.values {
      if let jobs {
        return jobs.first { $0.id == jobId }
      }
    }
    return nil
  }

  /// A pull, which always answers, "still processing" included.
  private func refresh() async {
    guard let outcome = await app.refreshJob(jobId) else { return }
    notice = UseSmileIDSampleTransientNotice(message: label(outcome))
  }

  /// One line per outcome, in the other three apps' words: a flow keys off these strings.
  private func label(_ outcome: UseSmileIDSampleStatusRefresh) -> String {
    switch outcome {
    case .updated(let status, let message, _): UseSmileIDSampleStrings.statusRefreshResult(status: status.label, message: message)
    case .stillProcessing: UseSmileIDSampleStrings.statusRefreshProcessing
    case .notRecorded: UseSmileIDSampleStrings.statusRefreshFailed(reason: UseSmileIDSampleJobStore.notRecordedDetail)
    case .noSession: UseSmileIDSampleStrings.statusRefreshNoSession
    case .noServerJob: UseSmileIDSampleStrings.statusRefreshNotTokenJob
    case .partnerMismatch: UseSmileIDSampleStrings.statusRefreshOtherPartner
    case .failed(let reason): UseSmileIDSampleStrings.statusRefreshFailed(reason: reason)
    }
  }

  /// `UIPasteboard` has no clip label, so only the value crosses.
  private func copy(_: String, _ value: String) {
    UIPasteboard.general.string = value
  }
}

/// The list, the clock it reads coarsely, and the row a tap opens.
private struct UseSmileIDSampleVerificationsHost: View {
  let navigator: NjiaNavigator

  @EnvironmentObject private var app: UseSmileIDSampleAppState

  var body: some View {
    VerificationsScreen(
      state: .init(
        jobs: app.jobs,
        counts: app.jobCounts,
        filter: app.verifications.filter,
        selectMode: app.verifications.selectMode,
        selected: app.verifications.selected,
        // Midnight, so a per-second tick cannot invalidate the grouping.
        today: useSmileIDSampleStartOfDay(app.now)
      ),
      onFilterChange: { app.verifications.filter = $0 },
      onSelectModeChange: { app.verifications.changeSelectMode($0) },
      onSelectionChange: { id, checked in app.verifications.setSelection(id, checked) },
      onJobTap: { navigator.go(.verificationDetails, arg: $0.id) },
      onRemove: { app.removeJobs($0) }
    )
    // No endpoint lists a partner's jobs, so the list asks about each processing row, and again while one still is.
    .task(id: app.session?.id) {
      var attempt = 0
      while await app.refreshProcessingJobs() > 0 {
        guard let delay = UseSmileIDSampleJobStore.processingPollDelay(attempt: attempt) else { return }
        attempt += 1
        try? await Task.sleep(nanoseconds: UInt64(delay * 1000000000))
        if Task.isCancelled {
          return
        }
      }
    }
  }
}

/// The profiles list and its created confirmation; the id is consumed on sight, so returning cannot re-show it.
private struct UseSmileIDSampleProfilesHost: View {
  let navigator: NjiaNavigator

  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var created: UseSmileIDSampleProfile?

  var body: some View {
    ProfilesScreen(
      state: .init(
        profiles: app.profiles.all,
        activeId: app.profiles.activeId,
        notice: created.map { .init(message: UseSmileIDSampleStrings.profilesCreated(profile: $0.title), actionLabel: UseSmileIDSampleStrings.profilesMakeActive) }
      ),
      onProfileTap: { navigator.go(.profileConfig, arg: $0.id) },
      onCreate: { navigator.go(.newProfile) },
      onBack: navigator.back,
      // A new profile is not made active by creating it, so the confirmation carries the offer.
      onNoticeAction: { created.map { app.profiles.setActive($0.id) } },
      onNoticeDismiss: { created = nil }
    )
    .onAppear(perform: consumeCreated)
    .onChange(of: app.profiles.lastCreatedId) { _ in consumeCreated() }
  }

  private func consumeCreated() {
    guard let id = app.profiles.lastCreatedId else { return }
    app.profiles.clearLastCreated()
    created = app.profiles.find(id)
  }
}
