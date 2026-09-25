import SampleUI
import SwiftUI

/// Binds a route to its screen; the mapping is the shell's because only it knows the route table.
struct UseSmileIDSampleDestination: View {
  let route: Route

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var inAppLink: UseSmileIDSampleInAppLink?

  var body: some View {
    switch route {
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
        onProduct: { product in
          // Every run starts from the active profile, including one whose form the token skips.
          app.fillFormForRun()
          router.open(app.firstStep(for: product))
        },
        onProfile: { router.sheet = .profileSwitch },
        // Pushed, not opened: linking pops back to where the scan started.
        onScan: { router.pushOnce(.scanToken) }
      )
    case .verifications:
      UseSmileIDSampleVerificationsHost()
    case .consentDetailsForm(let productId):
      UserDetailsScreen(
        state: .init(
          productLabel: Self.product(productId)?.label ?? productId,
          details: app.userDetails,
          profile: app.profiles.active,
          profileIndex: app.profiles.activeIndex,
          saveToProfile: app.saveToProfile,
          organisation: app.organisationDraft,
          requirement: app.userDetailsRequirement
        ),
        onFieldChange: { field, value in app.setUserField(field, to: value) },
        onSaveToProfileChange: { app.saveToProfile = $0 },
        onOrganisationChange: { app.organisationDraft = $0 },
        onProfileTap: { router.sheet = .profileSwitch },
        onBack: { router.pop() },
        // Pushed once: two quick taps would stack two flow levels, and so two runs.
        onContinue: {
          guard let product = Self.product(productId) else { return }
          app.keepUserDetails()
          router.pushOnce(app.stepAfterUserDetails(product))
        }
      )
      .navigationBarHidden(true)
      .onAppear { app.fillFormOnEntry() }
    case .idDetailsForm(let productId):
      KycIdFormScreen(
        state: .init(productLabel: Self.product(productId)?.label ?? productId, details: app.idDetails),
        onCountryTap: { router.sheet = .countryPicker },
        onIdTypeTap: { router.sheet = .idTypePicker },
        onIdNumberChange: { app.idDetails.idNumber = $0 },
        onBack: { router.pop() },
        onContinue: { Self.product(productId).map { router.pushOnce(app.sdkFlow($0)) } },
        onToken: { router.pushOnce(.scanToken) }
      )
      .navigationBarHidden(true)
    case .verificationDetails(let jobId):
      UseSmileIDSampleVerificationDetailsHost(jobId: jobId)
        .navigationBarHidden(true)
    case .profiles:
      UseSmileIDSampleProfilesHost()
        .navigationBarHidden(true)
    case .profileConfig(let profileId):
      if let profile = app.profiles.find(profileId) {
        profileConfig(profile)
      } else {
        Color.clear.onAppear {
          // Only while it is still on top: a delete has already popped it, and a second pop would take the list too.
          if router.path(router.selectedTab).last == route {
            router.pop()
          }
        }
      }
    case .sdkFlow(let productId, let presentation):
      SdkFlowScreen(productId: productId, presentation: presentation)
    case .scanToken:
      UseSmileIDSampleScanTokenHost()
        .navigationBarHidden(true)
    case .settings:
      browser(SettingsScreen(
        state: .init(
          settings: app.settings,
          organisation: app.organisation,
          initials: app.initials,
          versionLabel: app.versionLabel,
          avatarColor: app.avatarColor,
          hasProfile: app.profiles.active != nil
        ),
        onSettingChange: { setting, enabled in app.change(setting, to: enabled) },
        onProfile: { router.open(.profiles) },
        onNavRow: { row in open(row) },
        // No launch argument reveals it: every flow reaches the drawer by deep link.
        onOpenScenarioDrawer: UseSmileIDSampleAppState.isDebugBuild ? { router.sheet = .scenarioDrawer } : nil,
        // There is no auth to leave; the session is the local state a partner would expect gone.
        onSignOut: { app.signOut()
          // The pill's own cross-tab switch, so the stack lands where selecting Products would.
          router.selectedTab = .products }
      ))
    case .licenses:
      LicensesScreen(
        licenses: Self.notices,
        onBack: { router.pop() },
        // Ejects, as the legal rows above it do; no shipped component takes this path today.
        onOpenUrl: { link in URL(string: link).map { UIApplication.shared.open($0) } }
      )
      .navigationBarHidden(true)
    default:
      UseSmileIDSampleSeat(name: String(describing: route))
    }
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
        router.pop() },
      onSave: { app.saveProfile(id)
        router.pop() },
      onDelete: { router.pop()
        app.deleteProfile(id) }
    )
    .navigationBarHidden(true)
  }

  private static func product(_ id: String) -> UseSmileIDSampleProduct? {
    UseSmileIDSampleProduct(rawValue: id)
  }

  /// Read once: the asset is generated into the binary, so it cannot change while the app runs.
  private static let notices = UseSmileIDSampleLicenses.bundled()

  /// `UIPasteboard` has no clip label, so only the value crosses.
  private func copy(_: String, _ value: String) {
    UIPasteboard.general.string = value
  }

  /// A layer over the screen that opened it, never a destination.
  private func browser(_ content: some View) -> some View {
    content.sheet(item: $inAppLink) { UseSmileIDSampleBrowser(url: $0.url) }
  }

  /// No url is this app's own screen, `opensInApp` stays in a sheet, and the legal pages eject because both serve a PDF.
  private func open(_ row: UseSmileIDSampleNavRow) {
    guard let url = row.url else {
      router.open(.licenses)
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

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var notice: UseSmileIDSampleTransientNotice?

  var body: some View {
    VerificationDetailsScreen(
      state: .init(
        jobId: jobId,
        job: app.jobs?.first { $0.id == jobId },
        result: app.flowResult.snapshot,
        showProbes: app.showProbes
      ),
      resultExpanded: $app.resultCardExpanded,
      onBack: { router.pop() },
      // Hidden from this app's list, not deleted at the API: the store's own word for it.
      onDelete: { app.removeJobs([jobId])
        router.pop() },
      onCopy: { label, value in copy(label, value) },
      onRefresh: { await refresh(silentWhenUnchanged: false) }
    )
    .task(id: jobId) {
      // Off the store's first emission: nil is "not loaded yet", not "no row".
      guard await loaded(jobId)?.status == .processing else { return }
      await refresh(silentWhenUnchanged: true)
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

  private func refresh(silentWhenUnchanged: Bool) async {
    guard let outcome = await app.refreshJob(jobId) else { return }
    if silentWhenUnchanged, outcome == .stillProcessing {
      return
    }
    notice = UseSmileIDSampleTransientNotice(message: label(outcome))
  }

  /// One line per outcome, in the other three apps' words: a flow keys off these strings.
  private func label(_ outcome: UseSmileIDSampleStatusRefresh) -> String {
    switch outcome {
    case .updated(let status, let message, _): "\(status.label) — \(message)"
    case .stillProcessing: "Still processing"
    case .noSession: "Scan a token first"
    case .noServerJob: "Not submitted under a scanned token"
    case .partnerMismatch: "Submitted by a different partner"
    case .failed(let reason): "Could not check status: \(reason)"
    }
  }

  /// `UIPasteboard` has no clip label, so only the value crosses.
  private func copy(_: String, _ value: String) {
    UIPasteboard.general.string = value
  }
}

/// The list, the clock it reads coarsely, and the row a tap opens.
private struct UseSmileIDSampleVerificationsHost: View {
  @EnvironmentObject private var router: UseSmileIDSampleRouter
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
      onJobTap: { router.push(.verificationDetails(jobId: $0.id)) },
      onRemove: { app.removeJobs($0) }
    )
  }
}

/// The profiles list and its created confirmation; the id is consumed on sight, so returning cannot re-show it.
private struct UseSmileIDSampleProfilesHost: View {
  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var created: UseSmileIDSampleProfile?

  var body: some View {
    ProfilesScreen(
      state: .init(
        profiles: app.profiles.all,
        activeId: app.profiles.activeId,
        notice: created.map { .init(message: "\($0.title) created", actionLabel: "Make active") }
      ),
      onProfileTap: { router.push(.profileConfig(profileId: $0.id)) },
      onCreate: { router.sheet = .newProfile },
      onBack: { router.pop() },
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

/// A named seat for a screen U3 has not built yet.
struct UseSmileIDSampleSeat: View {
  let name: String

  var body: some View {
    Text(name)
  }
}
