import Combine
import SampleUI
import SwiftUI

/// What the shell holds on the app's behalf: the configuration every screen reads, and the profile
/// that names it. An `ObservableObject`, not `@Observable`, because the floor is iOS 15.
///
/// Writes live here rather than in a screen so a setting survives the screen that changed it.
final class UseSmileIDSampleAppState: ObservableObject {
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

  /// The active session, which the products strip renders and the nav ring counts down.
  @Published var sessionId: String?
  @Published var sessionRemaining: String?
  @Published var sessionEnded = false

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

  /// What the token still leaves the form to collect; every field until the token session lands.
  var userDetailsRequirement: UseSmileIDSampleUserDetailsRequirement {
    UseSmileIDSampleUserDetailsRequirement()
  }

  var versionLabel: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    return "UseSmileID Sample \(version)"
  }
}
