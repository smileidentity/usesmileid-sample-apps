import Combine
import SampleUI
import SwiftUI

/// What the shell holds for every screen: configuration, profile, token session and the clock, so a write survives the screen that made it.
@MainActor
final class UseSmileIDSampleAppState: ObservableObject {
  /// Persists the token session as one record, so the live half and the ended marker never disagree.
  let store: UseSmileIDSampleStore

  /// The submitted verifications; its writes are launched here rather than in a screen.
  let jobStore: UseSmileIDSampleJobStore

  /// Read once at launch; `appLocale` reaches the shell's own formatting, not the SDK's strings.
  let launchArguments: UseSmileIDSampleLaunchArguments

  /// Seeded from the store at launch and written back through it, so the six switches survive the process deaths the camera causes.
  @Published private(set) var settings: UseSmileIDSampleSettings

  /// The profiles the app can act as; the active one names the products header and the settings summary.
  @Published var profiles: UseSmileIDSampleProfiles

  /// The new-profile sheet's fields, cleared with the sheet so it opens empty each time.
  @Published var newProfile = UseSmileIDSampleNewProfile()

  /// The config screen's unsaved edits, keyed by profile, so a tab switch cannot lose them.
  @Published var profileDrafts: [String: UseSmileIDSampleUserDetails] = [:]

  /// Nil is "not loaded yet", not "empty": the store's first emission resolves it.
  @Published private(set) var jobs: [UseSmileIDSampleJob]?

  /// The last removal's size, consumed by whichever screen draws the confirmation.
  @Published private(set) var lastJobRemoval: Int?

  /// The list's filter and selection, here rather than in the screen: one tab is mounted at a time.
  @Published var verifications = UseSmileIDSampleVerificationsScreenState()

  /// The forms live here, not in the screens: one tab is mounted, so a tab switch would lose part-entered input.
  @Published var userDetails = UseSmileIDSampleUserDetails()
  @Published var rememberDetails = false
  @Published var idDetails = UseSmileIDSampleIdDetails()

  /// The pickers' search text, cleared on open so a sheet never reopens filtered.
  @Published var countryQuery = ""
  @Published var idTypeQuery = ""

  /// Both halves from one read, per the store's contract.
  @Published private(set) var sessionRecord: UseSmileIDSampleSessionRecord

  /// The one clock the ring, card and countdown read, ticking while a session is live; no screen owns a timer.
  @Published private(set) var now = Date()

  /// The scan sheet's typed state, lifted here so a tab switch or a recreation keeps it (R6).
  @Published var scanEntry = UseSmileIDSampleScanSheetState()

  /// The expiry gate's hand-off, claimed by the scanner on arrival so leaving elsewhere drops it.
  @Published var interruptedRun: UseSmileIDSampleRunIntent?

  /// The run the card reports: seeded from the launch, then the drawer's; see the type for what survives what.
  @Published var flowResult: UseSmileIDSampleFlowResult

  /// The card's toggle, here so a tab switch cannot re-expand it.
  @Published var resultCardExpanded = true

  private var ticker: Task<Void, Never>?
  private var jobsTask: Task<Void, Never>?
  private var removalsTask: Task<Void, Never>?

  init(
    store: UseSmileIDSampleStore = UseSmileIDSampleStore(),
    jobStore: UseSmileIDSampleJobStore = UseSmileIDSampleJobStore(source: UseSmileIDSampleStatusApi()),
    launchArguments: UseSmileIDSampleLaunchArguments = UseSmileIDSampleLaunchArguments(reading: .standard)
  ) {
    self.store = store
    self.jobStore = jobStore
    self.launchArguments = launchArguments
    settings = store.settings
    profiles = UseSmileIDSampleProfiles.forLaunch(seedProfiles: launchArguments.seedProfiles)
    flowResult = UseSmileIDSampleFlowResult(
      scenario: launchArguments.scenario,
      theme: launchArguments.theme,
      route: launchArguments.route
    )
    sessionRecord = store.session
    tick()
    readJobs()
    // Seeded after the subscription, so the rows arrive as an emission rather than needing a reload.
    if launchArguments.seedJobs {
      Task { await jobStore.seedFixtures(now: Date()) }
    }
  }

  /// For the life of the process: one tab is mounted, so a screen's subscription would miss a write.
  private func readJobs() {
    jobsTask = Task { [jobStore] in
      for await rows in await jobStore.jobStream() {
        jobs = rows
      }
    }
    removalsTask = Task { [jobStore] in
      for await count in await jobStore.removals {
        lastJobRemoval = count
      }
    }
  }

  /// Unstructured, never `.task`: the write outlives the flow the result is tearing down.
  func addJob(_ job: UseSmileIDSampleJob, bindings: UseSmileIDSampleTokenBindings?) {
    Task { [jobStore] in await jobStore.add(job, bindings: bindings) }
  }

  /// One handler for all three removal paths; unstructured, never `.task`, so the write outlives the screen.
  func removeJobs(_ ids: Set<String>) {
    Task { [jobStore] in await jobStore.remove(ids) }
    verifications.changeSelectMode(false)
    // Against the list minus the ids, since the write has not landed: else the screen is blank under a 0.
    if jobs?.contains(where: { !ids.contains($0.id) && verifications.filter.matches($0) }) == false {
      verifications.filter = .all
    }
  }

  /// Counted off the same list the rows render from, so a count cannot disagree with the screen.
  var jobCounts: [UseSmileIDSampleJobFilter: Int] {
    let jobs = jobs ?? []
    return Dictionary(
      uniqueKeysWithValues: UseSmileIDSampleJobFilter.allCases.map { ($0, jobs.filter($0.matches).count) }
    )
  }

  /// Screen-scoped, unlike a write: leaving cancels it, and the store releases its guard either way.
  func refreshJob(_ jobId: String) async -> UseSmileIDSampleStatusRefresh? {
    try? await jobStore.refresh(jobId, live: session, now: Date())
  }

  func undoJobRemoval() {
    Task { [jobStore] in await jobStore.undoRemove() }
  }

  /// Consumed on sight, so returning to the list cannot replay a confirmation already spent.
  func clearLastJobRemoval() {
    lastJobRemoval = nil
  }

  var session: UseSmileIDSampleTokenSession? {
    sessionRecord.live
  }

  /// Sandbox unless a linked token's `api_url` names production; there is no control for it.
  var useSandbox: Bool {
    session?.environment != .production
  }

  /// The session that ran out, once its token has been deleted. Carries no credential.
  var endedSession: UseSmileIDSampleEndedSession? {
    sessionRecord.ended
  }

  var sessionActive: Bool {
    session.map { !$0.hasExpired(at: now) } ?? false
  }

  /// True from the deadline on. Reads the marker too, since the token is deleted at expiry.
  var sessionExpired: Bool {
    endedSession != nil || session?.hasExpired(at: now) == true
  }

  /// 1 fresh to 0 expired for the nav ring; nil with no live session, so the ring is absent rather than empty.
  var sessionProgress: Double? {
    sessionActive ? session?.progress(at: now) : nil
  }

  var sessionId: String? {
    sessionActive ? session?.id : nil
  }

  var sessionRemaining: String? {
    sessionActive ? session.map { useSmileIDSampleCountdown($0.remaining(at: now)) } : nil
  }

  /// Takes a decoded session, never a raw token, so only what the decoder accepted is ever linked.
  func linkSession(_ session: UseSmileIDSampleTokenSession) {
    store.linkTokenSession(session)
    reload()
  }

  /// Sign out: the session goes with no ended marker, which would send the next run to the scanner, and the forms go with it because they hold PII.
  func signOut() {
    store.clearTokenSession()
    userDetails = UseSmileIDSampleUserDetails()
    rememberDetails = false
    idDetails = UseSmileIDSampleIdDetails()
    reload()
  }

  private func reload() {
    sessionRecord = store.session
    now = Date()
    tick()
  }

  /// Stops at the deadline: the session object does not change on expiry, so the loop is what ends it.
  private func tick() {
    ticker?.cancel()
    guard let live = session else { return }
    ticker = Task { [weak self] in
      while let self, !Task.isCancelled {
        now = Date()
        if live.hasExpired(at: now) {
          // Past the deadline the token is useless: delete it, keeping only that the session ended.
          store.retireTokenSession(live)
          sessionRecord = store.session
          return
        }
        try? await Task.sleep(nanoseconds: Self.tickNanoseconds)
      }
    }
  }

  private static let tickNanoseconds: UInt64 = 1000000000

  var organisation: String {
    profiles.active.organisation
  }

  var initials: String {
    profiles.active.initials
  }

  var avatarColor: Color {
    useSmileIDSampleAvatarColor(profileIndex: profiles.activeIndex)
  }

  /// Written through the store, which holds the mutex, so agent mode and enhanced liveness cannot both end up on.
  func change(_ setting: UseSmileIDSampleSetting, to enabled: Bool) {
    settings = store.setSetting(setting, enabled)
  }

  func setUserField(_ field: UseSmileIDSampleUserField, to value: String) {
    userDetails = field.write(userDetails, value)
  }

  /// Everything a sheet types into, dropped when it closes so no sheet reopens mid-entry.
  func clearSheetState() {
    countryQuery = ""
    idTypeQuery = ""
    newProfile = UseSmileIDSampleNewProfile()
  }

  /// The edits the config screen shows: the draft if one exists, else the profile's saved defaults.
  func profileDraft(for id: String) -> UseSmileIDSampleUserDetails {
    profileDrafts[id] ?? profiles.find(id)?.defaults ?? UseSmileIDSampleUserDetails()
  }

  func editProfileDraft(_ id: String, _ field: UseSmileIDSampleUserField, to value: String) {
    profileDrafts[id] = field.write(profileDraft(for: id), value)
  }

  func discardProfileDraft(_ id: String) {
    profileDrafts[id] = nil
  }

  /// The CTA reads "Make this profile active", so it has to do both.
  func saveProfile(_ id: String) {
    profiles.setDefaults(id, profileDraft(for: id))
    profiles.setActive(id)
    profileDrafts[id] = nil
  }

  func createProfile() {
    profiles.add(organisation: newProfile.name, person: newProfile.person, defaults: newProfile.defaults)
  }

  /// The types are country-specific, so a country change drops the ID type with it.
  func selectCountry(_ country: UseSmileIDSampleCountry) {
    guard country != idDetails.country else { return }
    idDetails.country = country
    idDetails.idType = nil
  }

  /// What the token leaves the form to collect, read through the gate's own rule so a skipped form cannot redirect back.
  var userDetailsRequirement: UseSmileIDSampleUserDetailsRequirement {
    UseSmileIDSampleUserDetailsRequirement(bindings: sessionActive ? session?.bindings : nil)
  }

  var versionLabel: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    return "UseSmileID Sample \(version)"
  }

  /// The card and its counters are always on in debug; a release build shows them on request only.
  var showProbes: Bool {
    Self.isDebugBuild || launchArguments.probes
  }

  /// What the Compose twin reads as `BuildConfig.DEBUG`: the Debug configuration's compilation condition.
  static let isDebugBuild: Bool = {
    #if DEBUG
      true
    #else
      false
    #endif
  }()
}
