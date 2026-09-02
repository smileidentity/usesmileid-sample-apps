@testable import SampleUI
import XCTest

final class UseSmileIDSampleProfilesTest: XCTestCase {
  func testInitialsTakeTheFirstTwoWordsOfThePerson() {
    XCTAssertEqual(profile(person: "Kwame Asante").initials, "KA")
    XCTAssertEqual(profile(person: "Mary Anne Smith").initials, "MA")
    XCTAssertEqual(profile(person: "amina").initials, "A")
  }

  /// A new profile has an organisation before it has a person, and the avatar still needs letters.
  func testInitialsFallBackToTheOrganisationThenToAPlaceholder() {
    XCTAssertEqual(profile(person: "   ", organisation: "PesaLink").initials, "P")
    XCTAssertEqual(profile(person: "", organisation: "").initials, "?")
  }

  func testTheFirstSeededProfileIsActiveUntilOneIsChosen() {
    var profiles = UseSmileIDSampleProfiles()
    XCTAssertEqual(profiles.activeId, "p-1")
    XCTAssertEqual(profiles.activeIndex, 0)
    profiles.setActive("p-3")
    XCTAssertEqual(profiles.active.organisation, "PesaLink")
    XCTAssertEqual(profiles.activeIndex, 2)
    // An id that names nothing leaves the choice alone rather than orphaning the header.
    profiles.setActive("p-9")
    XCTAssertEqual(profiles.activeId, "p-3")
  }

  func testAddPicksTheFirstFreeIdRatherThanTheCount() {
    var profiles = UseSmileIDSampleProfiles(seed: [
      profile(id: "p-1"), profile(id: "p-2"), profile(id: "p-4")
    ])
    XCTAssertEqual(profiles.add(organisation: "Acme", person: "Ada Lovelace").id, "p-5")
    XCTAssertEqual(profiles.add(organisation: "Beta", person: "Bob Ray").id, "p-6")
    XCTAssertEqual(profiles.all.map(\.id), ["p-1", "p-2", "p-4", "p-5", "p-6"])
  }

  /// Creating does not activate: the confirmation carries that offer, and it is consumed once.
  func testAddRecordsTheCreatedProfileWithoutActivatingIt() {
    var profiles = UseSmileIDSampleProfiles()
    let created = profiles.add(
      organisation: "Acme Fintech",
      person: "Ada Lovelace",
      defaults: UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Lovelace")
    )
    XCTAssertEqual(profiles.lastCreatedId, created.id)
    XCTAssertEqual(profiles.activeId, "p-1")
    XCTAssertEqual(profiles.find(created.id)?.defaults.firstName, "Ada")
    profiles.clearLastCreated()
    XCTAssertNil(profiles.lastCreatedId)
  }

  func testSetDefaultsTouchesOnlyThatProfile() {
    var profiles = UseSmileIDSampleProfiles()
    let edited = UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante", email: "k@uptech.example")
    profiles.setDefaults("p-1", edited)
    profiles.setDefaults("p-9", edited)
    XCTAssertEqual(profiles.find("p-1")?.defaults, edited)
    XCTAssertEqual(profiles.find("p-2")?.defaults, UseSmileIDSampleUserDetails(firstName: "Amina", lastName: "Diallo"))
    XCTAssertEqual(profiles.all.count, 3)
  }

  func testCreateNeedsTheProfileNameAndBothRequiredNames() {
    XCTAssertFalse(UseSmileIDSampleNewProfile().canCreate)
    XCTAssertFalse(UseSmileIDSampleNewProfile(name: "Acme", firstName: "Ada").canCreate)
    XCTAssertFalse(UseSmileIDSampleNewProfile(name: "  ", firstName: "Ada", lastName: "Lovelace").canCreate)
    XCTAssertTrue(UseSmileIDSampleNewProfile(name: "Acme", firstName: "Ada", lastName: "Lovelace").canCreate)
  }

  func testTheNewProfileSeedsThePersonAndTheDefaults() {
    let draft = UseSmileIDSampleNewProfile(
      name: "Acme",
      firstName: "Ada",
      lastName: "Lovelace",
      email: "ada@acme.example",
      phone: ""
    )
    XCTAssertEqual(draft.person, "Ada Lovelace")
    XCTAssertEqual(UseSmileIDSampleNewProfile(name: "Acme", firstName: "Ada").person, "Ada")
    XCTAssertEqual(
      draft.defaults,
      UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Lovelace", email: "ada@acme.example")
    )
  }

  private func profile(id: String = "p-1", person: String, organisation: String = "UpTech Finance") -> UseSmileIDSampleProfile {
    UseSmileIDSampleProfile(id: id, organisation: organisation, person: person)
  }

  private func profile(id: String) -> UseSmileIDSampleProfile {
    profile(id: id, person: "Kwame Asante")
  }
}
