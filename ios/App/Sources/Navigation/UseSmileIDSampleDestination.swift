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
        onProduct: { product in router.open(app.firstStep(for: product)) },
        onProfile: { router.sheet = .profileSwitch },
        // Pushed, not opened: linking pops back to where the scan started, as the Compose twin does.
        onScan: { router.pushOnce(.scanToken) }
      )
    case .verifications:
      UseSmileIDSampleVerificationsHost()
    case .consentDetailsForm(let productId):
      UserDetailsScreen(
        state: .init(
          productLabel: Self.product(productId)?.label ?? productId,
          details: app.userDetails,
          rememberDetails: app.rememberDetails,
          requirement: app.userDetailsRequirement
        ),
        onFieldChange: { field, value in app.setUserField(field, to: value) },
        onRememberChange: { app.rememberDetails = $0 },
        onBack: { router.pop() },
        // Pushed once: two quick taps would stack two flow levels, and so two runs.
        onContinue: { Self.product(productId).map { router.pushOnce(app.stepAfterUserDetails($0)) } }
      )
      .navigationBarHidden(true)
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
      ProfileConfigScreen(
        state: .init(
          // Falls back to the id, so a link naming no profile still titles the screen.
          organisation: app.profiles.find(profileId)?.organisation ?? profileId,
          defaults: app.profileDraft(for: profileId),
          isActive: profileId == app.profiles.activeId
        ),
        onFieldChange: { field, value in app.editProfileDraft(profileId, field, to: value) },
        onBack: { app.discardProfileDraft(profileId)
          router.pop() },
        onSave: { app.saveProfile(profileId)
          router.pop() }
      )
      .navigationBarHidden(true)
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
          avatarColor: app.avatarColor
        ),
        onSettingChange: { setting, enabled in app.change(setting, to: enabled) },
        onProfile: { router.open(.profiles) },
        onNavRow: { row in open(row) },
        // Debug builds only, and no launch argument reveals it: every flow reaches the drawer by deep link.
        onOpenScenarioDrawer: UseSmileIDSampleAppState.isDebugBuild ? { router.sheet = .scenarioDrawer } : nil,
        // There is no auth to leave; the session is the local state a partner would expect gone.
        onSignOut: { app.clearSession() }
      ))
    default:
      UseSmileIDSampleSeat(name: String(describing: route))
    }
  }

  private static func product(_ id: String) -> UseSmileIDSampleProduct? {
    UseSmileIDSampleProduct(rawValue: id)
  }

  /// `UIPasteboard` has no clip label, so only the value crosses.
  private func copy(_: String, _ value: String) {
    UIPasteboard.general.string = value
  }

  /// A layer over the screen that opened it, never a destination.
  private func browser(_ content: some View) -> some View {
    content.sheet(item: $inAppLink) { UseSmileIDSampleBrowser(url: $0.url) }
  }

  /// Three destinations, per `spec/screens.json` → linkPresentation: no url is the app's own
  /// screen; `opensInApp` stays in an in-app browser; the two legal pages eject, because both serve
  /// their document as an embedded PDF a mobile browser shows as a stub.
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
      // Only a processing row can change, read off the store's first emission rather than whatever
      // a cold-start link found: nil is "not loaded yet", and treating it as a row refreshes a
      // settled one.
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

/// The profiles list plus the created confirmation it owns. The created id is consumed on sight, so
/// returning to the list cannot re-show it.
private struct UseSmileIDSampleProfilesHost: View {
  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var created: UseSmileIDSampleProfile?

  var body: some View {
    ProfilesScreen(
      state: .init(
        profiles: app.profiles.all,
        activeId: app.profiles.activeId,
        notice: created.map { .init(message: "\($0.organisation) created", actionLabel: "Make active") }
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
