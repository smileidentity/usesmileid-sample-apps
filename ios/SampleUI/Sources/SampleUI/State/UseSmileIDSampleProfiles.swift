import Foundation

/// One partner profile: who is signed in, and the defaults their jobs are seeded from.
public struct UseSmileIDSampleProfile: Equatable, Identifiable, Sendable {
  public let id: String
  public var organisation: String
  public var person: String
  public var defaults: UseSmileIDSampleUserDetails
  /// Empty means the partner's portal default.
  public var callbackUrl: String

  public init(
    id: String,
    organisation: String,
    person: String,
    defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    callbackUrl: String = ""
  ) {
    self.id = id
    self.organisation = organisation
    self.person = person
    self.defaults = defaults
    self.callbackUrl = callbackUrl
  }

  /// The person's initials, as the design has them, falling back to the organisation for a new profile.
  public var initials: String {
    let source = person.isBlank ? organisation : person
    let letters = source.split(separator: " ").prefix(2).compactMap { word in
      word.first.map { String($0).uppercased() }
    }
    return letters.isEmpty ? "?" : letters.joined()
  }

  /// What a row says under the organisation: the person, or a placeholder until details are saved.
  public var caption: String {
    person.isBlank ? Self.noUserDetailsCaption : person
  }

  static let noUserDetailsCaption = "No user details yet"
}

/// The profiles the app can act as, and which is active; in memory until profiles are a real account concern.
public struct UseSmileIDSampleProfiles: Equatable, Sendable {
  private var items: [UseSmileIDSampleProfile]
  public private(set) var activeId: String

  /// The last profile `add` created, until whoever confirmed it calls `clearLastCreated`.
  public private(set) var lastCreatedId: String?

  /// `seed` must not be empty, or the failure surfaces far from here as the products screen reading no active profile.
  public init(seed: [UseSmileIDSampleProfile] = UseSmileIDSampleProfiles.starter()) {
    precondition(!seed.isEmpty, "UseSmileIDSampleProfiles needs at least one profile")
    items = seed
    activeId = seed[0].id
  }

  public var all: [UseSmileIDSampleProfile] {
    items
  }

  public var active: UseSmileIDSampleProfile {
    items.first { $0.id == activeId } ?? items[0]
  }

  /// Position in the list, which is what picks a profile's avatar hue.
  public var activeIndex: Int {
    items.firstIndex { $0.id == activeId } ?? 0
  }

  public mutating func setActive(_ id: String) {
    if items.contains(where: { $0.id == id }) {
      activeId = id
    }
  }

  public mutating func clearLastCreated() {
    lastCreatedId = nil
  }

  public func find(_ id: String) -> UseSmileIDSampleProfile? {
    items.first { $0.id == id }
  }

  @discardableResult
  public mutating func add(
    organisation: String,
    person: String,
    defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails()
  ) -> UseSmileIDSampleProfile {
    // First free id, not one derived from the count: duplicate keys crash the list and double a test id.
    var number = items.count + 1
    while items.contains(where: { $0.id == "p-\(number)" }) {
      number += 1
    }
    let profile = UseSmileIDSampleProfile(
      id: "p-\(number)",
      organisation: organisation,
      person: person,
      defaults: defaults
    )
    items.append(profile)
    lastCreatedId = profile.id
    return profile
  }

  public mutating func setDefaults(
    _ id: String,
    _ defaults: UseSmileIDSampleUserDetails,
    callbackUrl: String = ""
  ) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    items[index].defaults = defaults
    items[index].callbackUrl = callbackUrl
    // The starter names nobody until its details are saved; a created profile keeps the name its sheet gave it.
    if items[index].person.isBlank {
      items[index].person = "\(defaults.firstName) \(defaults.lastName)".trimmingCharacters(in: .whitespaces)
    }
  }

  /// The fixtures only when `seedProfiles` asks; a Bool rather than the arguments type, which lives in the shell.
  public static func forLaunch(seedProfiles: Bool) -> UseSmileIDSampleProfiles {
    UseSmileIDSampleProfiles(seed: seedProfiles ? fixtures() : starter())
  }

  /// A plain launch: one empty profile, never the fixtures, since the active organisation names the partner on consent.
  public static func starter() -> [UseSmileIDSampleProfile] {
    [UseSmileIDSampleProfile(id: "p-1", organisation: starterOrganisation, person: "")]
  }

  /// Shown on the consent screen as the partner until a profile is created, so it must read as a placeholder.
  public static let starterOrganisation = "Default profile"

  /// The three the design's sheet shows. Reached only by the `seedProfiles` launch argument.
  public static func fixtures() -> [UseSmileIDSampleProfile] {
    [
      UseSmileIDSampleProfile(
        id: "p-1",
        organisation: "UpTech Finance",
        person: "Kwame Asante",
        defaults: UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante")
      ),
      UseSmileIDSampleProfile(
        id: "p-2",
        organisation: "Kazi Microlending",
        person: "Amina Diallo",
        defaults: UseSmileIDSampleUserDetails(firstName: "Amina", lastName: "Diallo")
      ),
      UseSmileIDSampleProfile(
        id: "p-3",
        organisation: "PesaLink",
        person: "Tunde Okafor",
        defaults: UseSmileIDSampleUserDetails(firstName: "Tunde", lastName: "Okafor")
      )
    ]
  }
}

/// The new-profile sheet's five fields, held outside the sheet so a tab switch cannot lose them.
public struct UseSmileIDSampleNewProfile: Equatable, Sendable {
  public var name: String
  public var firstName: String
  public var lastName: String
  public var email: String
  public var phone: String

  public init(name: String = "", firstName: String = "", lastName: String = "", email: String = "", phone: String = "") {
    self.name = name
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.phone = phone
  }

  /// The design's own rule: Create needs the profile name and both required names.
  public var canCreate: Bool {
    !name.isBlank && !firstName.isBlank && !lastName.isBlank
  }

  /// The person is the two required names; all four seed the details its jobs start from.
  public var person: String {
    "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
  }

  public var defaults: UseSmileIDSampleUserDetails {
    UseSmileIDSampleUserDetails(firstName: firstName, lastName: lastName, email: email, phone: phone)
  }
}
