import Combine
import SampleUI
import SwiftUI

/// What the shell holds on the app's behalf: the configuration every screen reads, the profile that
/// names it, the token session and the clock that ticks it. An `ObservableObject`, not `@Observable`,
/// because the floor is iOS 15.
///
/// Writes live here rather than in a screen so a setting survives the screen that changed it.
@MainActor
final class UseSmileIDSampleAppState: ObservableObject {
  /// Persists the token session as one record, so the live half and the ended marker never disagree.
  let store: UseSmileIDSampleStore

  @Published var settings = UseSmileIDSampleSettings()

  /// The profiles the app can act as; the active one names the products header and the settings summary.
  @Published var profiles = UseSmileIDSampleProfiles()

  /// The new-profile sheet's fields, cleared with the sheet so it opens empty each time.
  @Published var newProfile = UseSmileIDSampleNewProfile()

  /// The config screen's unsaved edits, keyed by profile, so a tab switch cannot lose them.
  @Published var profileDrafts: [String: UseSmileIDSampleUserDetails] = [:]

  /// Nil is "not loaded yet", not "empty"; the store U3 lands resolves it.
  @Published var jobs: [UseSmileIDSampleJob]?

  /// The forms live here, not in the screens: one tab is mounted, so a tab switch tears a screen's
  /// own state down and part-entered input goes with it.
  @Published var userDetails = UseSmileIDSampleUserDetails()
  @Published var rememberDetails = false
  @Published var idDetails = UseSmileIDSampleIdDetails()

  /// The pickers' search text, cleared on open so a sheet never reopens filtered.
  @Published var countryQuery = ""
  @Published var idTypeQuery = ""

  /// Both halves from one read, per the store's contract.
  @Published private(set) var sessionRecord: UseSmileIDSampleSessionRecord

  /// The one clock the ring, the card and the countdown read. Ticks once a second while a session is
  /// live and stops at its deadline, where the token is retired; nothing in a screen owns a timer.
  @Published private(set) var now = Date()

  /// The scan sheet's typed state, lifted here so a tab switch or a recreation keeps it (R6).
  @Published var scanEntry = UseSmileIDSampleScanSheetState()

  /// The run the card reports. The drawer owns the selection; see the type for what survives what.
  @Published var flowResult = UseSmileIDSampleFlowResult()

  /// The card's toggle, here so a tab switch cannot re-expand it. Not restored with the run: a
  /// restore re-expands, which puts every field back in the accessibility tree.
  @Published var resultCardExpanded = true

  /// A restore or a link wins once; after that the drawer's choice is the run's.
  private var flowResultRestored = false

  private var ticker: Task<Void, Never>?

  init(store: UseSmileIDSampleStore = UseSmileIDSampleStore()) {
    self.store = store
    sessionRecord = store.session
    tick()
  }

  var session: UseSmileIDSampleTokenSession? {
    sessionRecord.live
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

  /// Sign out: the session goes with no ended marker, which would send the next run to the scanner.
  func clearSession() {
    store.clearTokenSession()
    reload()
  }

  private func reload() {
    sessionRecord = store.session
    now = Date()
    tick()
  }

  /// Stops at the deadline: the session object does not change on expiry, so the loop is what ends
  /// it. A cold start after expiry takes the same path, the loop exiting at once.
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

  /// Goes through the settings mutex, so agent mode and enhanced liveness cannot both end up on.
  func change(_ setting: UseSmileIDSampleSetting, to enabled: Bool) {
    settings = settings.with(setting, enabled)
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

  /// What the token still leaves the form to collect, read through the live-session rule the gate
  /// will use, so a skipped form can never be followed by a redirect back to it.
  var userDetailsRequirement: UseSmileIDSampleUserDetailsRequirement {
    UseSmileIDSampleUserDetailsRequirement(bindings: sessionActive ? session?.bindings : nil)
  }

  var versionLabel: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    return "UseSmileID Sample \(version)"
  }

  /// The card and its counters are always on in debug; a release build shows them on request only.
  var showProbes: Bool {
    Self.isDebugBuild
  }

  /// What the Compose twin reads as `BuildConfig.DEBUG`: the Debug configuration's compilation condition.
  static let isDebugBuild: Bool = {
    #if DEBUG
      true
    #else
      false
    #endif
  }()

  /// Unreadable state keeps the seeded run rather than throwing into a blank card.
  func restoreFlowResult(from encoded: String) {
    guard !flowResultRestored else { return }
    flowResultRestored = true
    guard let data = encoded.data(using: .utf8),
          let saved = try? JSONDecoder().decode([String].self, from: data)
    else { return }
    flowResult = UseSmileIDSampleFlowResult(saved: saved)
  }

  func encodedFlowResult() -> String {
    guard let data = try? JSONEncoder().encode(flowResult.saved) else { return "" }
    return String(decoding: data, as: UTF8.self)
  }
}
