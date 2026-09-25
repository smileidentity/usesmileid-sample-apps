@testable import SampleUI
import XCTest

final class UseSmileIDSampleProfilesTest: XCTestCase {
  private let ada = UseSmileIDSampleUserDetails(firstName: "Ada", lastName: "Okafor", email: "ada@kobo.example")

  func testInitialsComeFromThePersonThenTheOrganisation() {
    XCTAssertEqual(profile(first: "Kwame", last: "Asante").initials, "KA")
    XCTAssertEqual(profile(first: "Mary Anne", last: "Smith").initials, "MA")
    XCTAssertEqual(profile(first: "amina").initials, "A")
    XCTAssertEqual(profile(organisation: "PesaLink").initials, "P")
    XCTAssertEqual(profile(organisation: "").initials, "?")
  }

  func testAPlainLaunchHasNoProfile() {
    let profiles = UseSmileIDSampleProfiles.forLaunch(seedProfiles: false, stored: UseSmileIDSampleProfiles())

    XCTAssertTrue(profiles.all.isEmpty)
    XCTAssertNil(profiles.active)
    XCTAssertEqual(profiles.partnerName, "Smile ID")
    XCTAssertEqual(profiles.partnerId, "p-1")
  }

  func testASeededLaunchShowsTheFixturesOverWhatWasStored() {
    let stored = UseSmileIDSampleProfiles([profile(organisation: "Kobo Bank")])

    XCTAssertEqual(UseSmileIDSampleProfiles.forLaunch(seedProfiles: true, stored: stored).all, UseSmileIDSampleProfiles.fixtures())
    XCTAssertEqual(UseSmileIDSampleProfiles.forLaunch(seedProfiles: false, stored: stored), stored)
  }

  func testTheFirstProfileBecomesActiveAndLaterOnesWaitForTheOffer() {
    var profiles = UseSmileIDSampleProfiles()

    let first = profiles.add(organisation: "Karibu Pay")
    XCTAssertEqual(profiles.activeId, first.id)
    XCTAssertNil(profiles.lastCreatedId, "the active one needs no Make active offer")

    let second = profiles.add(organisation: "Sahara Pay")
    XCTAssertEqual(profiles.activeId, first.id)
    XCTAssertEqual(profiles.lastCreatedId, second.id)
    XCTAssertEqual(profiles.all.map(\.id), ["p-1", "p-2"])
  }

  func testIdsSkipOnesAlreadyTaken() {
    var profiles = UseSmileIDSampleProfiles([profile(id: "p-1"), profile(id: "p-3"), profile(id: "p-4")])

    XCTAssertEqual(profiles.add(organisation: "Acme").id, "p-5")
    XCTAssertEqual(profiles.add(organisation: "Beta").id, "p-6")
  }

  func testABlankOrganisationNamesTheAppOnConsentNeverThePerson() {
    var profiles = UseSmileIDSampleProfiles()
    profiles.add(organisation: "", defaults: ada)

    XCTAssertEqual(profiles.active?.title, "Ada Okafor")
    XCTAssertEqual(profiles.partnerName, "Smile ID")
  }

  func testAnUpdateLeavesWhatItWasNotGiven() {
    var profiles = UseSmileIDSampleProfiles()
    let created = profiles.add(organisation: "Karibu Pay")
    profiles.update(created.id, callbackUrl: " https://partner.example/hook ")

    profiles.update(created.id, defaults: ada)

    XCTAssertEqual(profiles.active?.callbackUrl, "https://partner.example/hook")
    XCTAssertEqual(profiles.active?.organisation, "Karibu Pay")
    XCTAssertEqual(profiles.active?.person, "Ada Okafor")
  }

  func testDeletingTheActiveProfileHandsOverToTheFirstLeftThenToNone() {
    var profiles = UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures(), activeId: "p-2")

    profiles.delete("p-2")
    XCTAssertEqual(profiles.activeId, "p-1")

    profiles.delete("p-1")
    profiles.delete("p-3")
    XCTAssertNil(profiles.activeId)
  }

  func testSignOutClearsEveryProfile() {
    var profiles = UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures())

    profiles.clear()

    XCTAssertEqual(profiles, UseSmileIDSampleProfiles())
  }

  func testAStoredActiveIdThatNamesNoProfileFallsBackToTheFirst() {
    XCTAssertEqual(UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures(), activeId: "p-9").activeId, "p-1")
  }

  func testTheFirstRunCreatesAnActiveProfileFromWhatWasTyped() {
    var profiles = UseSmileIDSampleProfiles()

    profiles.keep(ada, organisation: " Kobo Bank ")

    XCTAssertEqual(profiles.active?.organisation, "Kobo Bank")
    XCTAssertEqual(profiles.active?.defaults, ada)
  }

  func testAnActiveProfileTakesTheEdits() {
    var profiles = UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures())

    profiles.keep(ada, organisation: "")

    XCTAssertEqual(profiles.find("p-1")?.defaults, ada)
    XCTAssertEqual(profiles.find("p-1")?.organisation, "UpTech Finance")
    XCTAssertEqual(profiles.all.count, 3)
  }

  func testAFieldTheTokenSuppliesIsNeverStored() {
    let stored = UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante")
    var profiles = UseSmileIDSampleProfiles([UseSmileIDSampleProfile(id: "p-1", organisation: "UpTech", defaults: stored)])
    let namesBound = UseSmileIDSampleUserDetailsRequirement(
      bindings: UseSmileIDSampleTokenBindings(givenNames: true, lastName: true)
    )

    profiles.keep(UseSmileIDSampleUserDetails(email: "ada@kobo.example"), organisation: "", requirement: namesBound)

    XCTAssertEqual(profiles.active?.defaults, UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante", email: "ada@kobo.example"))
  }

  func testARecordRoundTripsIncludingCharactersJsonEscapes() {
    let profiles = UseSmileIDSampleProfiles(
      [
        UseSmileIDSampleProfile(
          id: "p-1",
          organisation: "Kobo \"Bank\" \\ Ltd\n",
          defaults: UseSmileIDSampleUserDetails(firstName: "Adá", lastName: "O'Neil", email: "ada@kobo.example", phone: "+254 700"),
          callbackUrl: "https://kobo.example/hook?a=1&b=2"
        ),
        UseSmileIDSampleProfile(id: "p-2", organisation: "")
      ],
      activeId: "p-2"
    )

    XCTAssertEqual(UseSmileIDSampleProfilesCodec.decode(UseSmileIDSampleProfilesCodec.encode(profiles)), profiles)
  }

  func testUnreadableInputIsNoProfiles() {
    let inputs: [String?] = [
      nil,
      "",
      "not json",
      "[]",
      #"{"profiles":[{"id":"p-1"}]}"#,
      #"{"version":2,"profiles":[{"id":"p-1"}]}"#,
      #"{"version":1,"profiles":"p-1"}"#,
      #"{"version":1,"profiles":[{"id":"p-1","organisation":"Kobo""#
    ]
    for text in inputs {
      XCTAssertEqual(UseSmileIDSampleProfilesCodec.decode(text.map { Data($0.utf8) }), UseSmileIDSampleProfiles(), text ?? "nil")
    }
  }

  func testAProfileWithoutAnIdOrWithARepeatedOneIsDropped() {
    let text = #"{"version":1,"activeId":"p-1","profiles":[{"organisation":"No id"},{"id":"p-1","organisation":"First"},{"id":"p-1","organisation":"Again"}]}"#

    XCTAssertEqual(UseSmileIDSampleProfilesCodec.decode(Data(text.utf8)).all.map(\.organisation), ["First"])
  }

  func testTheAndroidShapeReadsTheSame() {
    let android = #"{"version":1,"activeId":"p-1","profiles":[{"id":"p-1","organisation":"Kobo","firstName":"Ada","lastName":"","email":"","phone":"","callbackUrl":""}]}"#

    let profiles = UseSmileIDSampleProfilesCodec.decode(Data(android.utf8))

    XCTAssertEqual(profiles.active?.organisation, "Kobo")
    XCTAssertEqual(profiles.active?.defaults.firstName, "Ada")
  }

  private func profile(
    id: String = "p-1",
    organisation: String = "UpTech Finance",
    first: String = "",
    last: String = ""
  ) -> UseSmileIDSampleProfile {
    UseSmileIDSampleProfile(
      id: id,
      organisation: organisation,
      defaults: UseSmileIDSampleUserDetails(firstName: first, lastName: last)
    )
  }
}
