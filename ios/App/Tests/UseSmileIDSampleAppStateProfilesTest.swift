import SampleUI
@testable import UseSmileIDSample
import XCTest

/// The profile rules that live in the app state: a seeded launch stores nothing, sign-out clears the record, and the switch off keeps nothing.
@MainActor
final class UseSmileIDSampleAppStateProfilesTest: XCTestCase {
  private var settings: UseSmileIDSampleMemorySettingsStorage!
  private var store: UseSmileIDSampleStore!

  override func setUp() {
    super.setUp()
    settings = UseSmileIDSampleMemorySettingsStorage()
    store = UseSmileIDSampleStore(
      storage: UseSmileIDSampleMemoryStorage(),
      settingsStorage: settings,
      profilesStorage: UseSmileIDSampleMemoryStorage()
    )
  }

  func testASeededLaunchStoresNothing() {
    let app = appState(seedProfiles: true)

    app.profiles.setActive("p-2")
    app.userDetails = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@kobo.example")
    app.keepUserDetails()

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles(), "fixtures reached the store")
  }

  func testSignOutClearsTheStoredProfilesAndTheDrafts() {
    store.setProfiles(UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures()))
    let app = appState()
    app.editProfileOrganisationDraft("p-1", to: "Typed then abandoned")

    app.signOut()

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles())
    // The next profile made reuses p-1, and must not inherit the last person's unsaved edits.
    app.profiles.add(organisation: "Kobo")
    XCTAssertEqual(app.profileOrganisationDraft(for: "p-1"), "Kobo")
  }

  func testTheFirstEntryOfALaunchFillsTheFormAndALaterOneKeepsTheTyping() {
    let stored = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@kobo.example")
    store.setProfiles(UseSmileIDSampleProfiles([UseSmileIDSampleProfile(id: "p-1", organisation: "Kobo", defaults: stored)]))
    let app = appState()

    app.fillFormOnEntry()
    XCTAssertEqual(app.userDetails, stored, "a cold link opened an empty form over a stored profile")

    app.setUserField(.email, to: "typed@kobo.example")
    app.fillFormOnEntry()
    XCTAssertEqual(app.userDetails.email, "typed@kobo.example", "coming back to the form refilled over the typing")
  }

  func testSigningOutOfASeededLaunchStillDeletesTheStoredProfiles() {
    store.setProfiles(UseSmileIDSampleProfiles([UseSmileIDSampleProfile(id: "p-1", organisation: "Kobo")]))
    let app = appState(seedProfiles: true)

    app.signOut()

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles())
  }

  func testANewRunNeverCarriesTheLastRunsIdDetails() {
    let app = appState()
    app.selectCountry(.kenya)
    app.idDetails.idNumber = "12345678"

    app.fillFormForRun()

    XCTAssertEqual(app.idDetails, UseSmileIDSampleIdDetails())
  }

  func testAnEntryAfterTheActiveProfileChangedFillsFromTheNewOne() {
    let amina = UseSmileIDSampleUserDetails(firstName: "Amina", lastName: "Diallo")
    store.setProfiles(UseSmileIDSampleProfiles([
      UseSmileIDSampleProfile(id: "p-1", organisation: "Kobo", defaults: UseSmileIDSampleUserDetails(firstName: "Ada")),
      UseSmileIDSampleProfile(id: "p-2", organisation: "Kazi", defaults: amina)
    ]))
    let app = appState()
    app.fillFormForRun()

    app.saveProfile("p-2")
    app.fillFormOnEntry()

    XCTAssertEqual(app.userDetails, amina, "the form kept the previous profile's details under the new one")
  }

  func testTheSwitchOffKeepsNothing() {
    let app = appState()
    app.userDetails = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@kobo.example")
    app.saveToProfile = false

    app.keepUserDetails()

    XCTAssertEqual(store.profiles, UseSmileIDSampleProfiles())
  }

  func testTheFirstRunKeepsTheTypingAsAStoredProfile() {
    let app = appState()
    app.userDetails = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@kobo.example")
    app.organisationDraft = "Kobo"

    app.keepUserDetails()

    XCTAssertEqual(store.profiles.active?.organisation, "Kobo")
  }

  private func appState(seedProfiles: Bool = false) -> UseSmileIDSampleAppState {
    UseSmileIDSampleAppState(
      store: store,
      jobStore: UseSmileIDSampleJobStore(source: NoNetwork()),
      launchArguments: UseSmileIDSampleLaunchArguments(raw: ["seedProfiles": seedProfiles ? "true" : nil])
    )
  }
}

/// A status source that is never reached here.
private struct NoNetwork: UseSmileIDSampleJobStatusSource {
  func check(jobId _: String, token _: String, sandbox _: Bool) async throws -> UseSmileIDSampleStatusRefresh {
    .stillProcessing
  }
}
