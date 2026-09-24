import Foundation

/// One persona a job runs as: the organisation the SDK's consent screen names, and the details its jobs carry.
public struct UseSmileIDSampleProfile: Equatable, Identifiable, Sendable, Codable {
  public let id: String
  /// May be blank, when consent names the app itself rather than the person being verified.
  public var organisation: String
  public var defaults: UseSmileIDSampleUserDetails
  /// Empty means the partner's portal default.
  public var callbackUrl: String

  public init(
    id: String,
    organisation: String,
    defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    callbackUrl: String = ""
  ) {
    self.id = id
    self.organisation = organisation
    self.defaults = defaults
    self.callbackUrl = callbackUrl
  }

  /// The person the details name, so it can never disagree with them.
  public var person: String {
    "\(defaults.firstName) \(defaults.lastName)".trimmingCharacters(in: .whitespaces)
  }

  /// What a row calls it: the organisation, or the person when it names none.
  public var title: String {
    if !organisation.isBlank {
      return organisation
    }
    return person.isBlank ? Self.unnamed : person
  }

  /// The person's initials, as the design has them, falling back to the organisation.
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

  /// A profile naming neither an organisation nor a person, which only a token binding both names allows.
  static let unnamed = "Unnamed profile"

  enum CodingKeys: String, CodingKey {
    case id, organisation, firstName, lastName, email, phone, callbackUrl
  }

  /// Flat, as the other three apps store it; a missing field reads as empty.
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    organisation = try values.decodeIfPresent(String.self, forKey: .organisation) ?? ""
    defaults = try UseSmileIDSampleUserDetails(
      firstName: values.decodeIfPresent(String.self, forKey: .firstName) ?? "",
      lastName: values.decodeIfPresent(String.self, forKey: .lastName) ?? "",
      email: values.decodeIfPresent(String.self, forKey: .email) ?? "",
      phone: values.decodeIfPresent(String.self, forKey: .phone) ?? ""
    )
    callbackUrl = try values.decodeIfPresent(String.self, forKey: .callbackUrl) ?? ""
  }

  public func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: CodingKeys.self)
    try values.encode(id, forKey: .id)
    try values.encode(organisation, forKey: .organisation)
    try values.encode(defaults.firstName, forKey: .firstName)
    try values.encode(defaults.lastName, forKey: .lastName)
    try values.encode(defaults.email, forKey: .email)
    try values.encode(defaults.phone, forKey: .phone)
    try values.encode(callbackUrl, forKey: .callbackUrl)
  }
}

/// The profiles the app can act as, and which is active. A plain first launch has none: no profile is a state of its own, never an empty placeholder that reads as one already set up.
public struct UseSmileIDSampleProfiles: Equatable, Sendable {
  public private(set) var all: [UseSmileIDSampleProfile]
  /// Nil exactly when there are no profiles.
  public private(set) var activeId: String?

  /// The last profile `add` created without activating, until the list that offers "Make active" consumes it.
  public private(set) var lastCreatedId: String?

  public init(_ profiles: [UseSmileIDSampleProfile] = [], activeId: String? = nil) {
    var seen = Set<String>()
    all = profiles.filter { seen.insert($0.id).inserted }
    self.activeId = activeId.flatMap { id in all.contains { $0.id == id } ? id : nil } ?? all.first?.id
  }

  public var active: UseSmileIDSampleProfile? {
    all.first { $0.id == activeId }
  }

  /// Position in the list, which is what picks a profile's avatar hue.
  public var activeIndex: Int {
    all.firstIndex { $0.id == activeId } ?? 0
  }

  /// What the consent screen names as the partner: the app's own name when no profile names one.
  public var partnerName: String {
    guard let organisation = active?.organisation, !organisation.isBlank else { return Self.noProfilePartnerName }
    return organisation
  }

  /// The id a job runs under without a token: the first profile's own id when there is none yet.
  public var partnerId: String {
    active?.id ?? Self.firstProfileId
  }

  public mutating func setActive(_ id: String) {
    if all.contains(where: { $0.id == id }) {
      activeId = id
    }
  }

  public mutating func clearLastCreated() {
    lastCreatedId = nil
  }

  public func find(_ id: String) -> UseSmileIDSampleProfile? {
    all.first { $0.id == id }
  }

  /// The first profile ever made becomes active, so a list with profiles always has one active.
  @discardableResult
  public mutating func add(
    organisation: String,
    defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    activate: Bool = false
  ) -> UseSmileIDSampleProfile {
    // First free id, not one derived from the count: duplicate keys crash the list and double a test id.
    var number = all.count + 1
    while all.contains(where: { $0.id == "p-\(number)" }) {
      number += 1
    }
    let profile = UseSmileIDSampleProfile(
      id: "p-\(number)",
      organisation: organisation.trimmingCharacters(in: .whitespaces),
      defaults: defaults
    )
    all.append(profile)
    if activate || activeId == nil {
      activeId = profile.id
    } else {
      lastCreatedId = profile.id
    }
    return profile
  }

  /// A nil argument leaves that part alone.
  public mutating func update(
    _ id: String,
    organisation: String? = nil,
    defaults: UseSmileIDSampleUserDetails? = nil,
    callbackUrl: String? = nil
  ) {
    guard let index = all.firstIndex(where: { $0.id == id }) else { return }
    if let organisation {
      all[index].organisation = organisation.trimmingCharacters(in: .whitespaces)
    }
    if let defaults {
      all[index].defaults = defaults
    }
    if let callbackUrl {
      all[index].callbackUrl = callbackUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  /// Deleting the active profile hands over to the first one left, so a list with profiles always has one active.
  public mutating func delete(_ id: String) {
    all.removeAll { $0.id == id }
    if activeId == id {
      activeId = all.first?.id
    }
    if lastCreatedId == id {
      lastCreatedId = nil
    }
  }

  /// Sign out: every profile goes, which is how a phone is handed to the next person.
  public mutating func clear() {
    self = UseSmileIDSampleProfiles()
  }

  /// The fixtures only when `seedProfiles` asks; the shell never stores them, so an automation run leaves nobody behind.
  public static func forLaunch(seedProfiles: Bool, stored: UseSmileIDSampleProfiles) -> UseSmileIDSampleProfiles {
    seedProfiles ? UseSmileIDSampleProfiles(fixtures()) : stored
  }

  /// The partner the consent screen names when no profile does.
  public static let noProfilePartnerName = "Smile ID"

  /// What a plain launch has always sent as the partner id, so no profile changes nothing on the wire.
  public static let firstProfileId = "p-1"

  /// What the header, settings card and form say while there is no profile.
  public static let noProfileLabel = "No profile yet"

  /// The three the design's sheet shows. Reached only by the `seedProfiles` launch argument.
  public static func fixtures() -> [UseSmileIDSampleProfile] {
    [
      UseSmileIDSampleProfile(
        id: "p-1",
        organisation: "UpTech Finance",
        defaults: UseSmileIDSampleUserDetails(firstName: "Kwame", lastName: "Asante")
      ),
      UseSmileIDSampleProfile(
        id: "p-2",
        organisation: "Kazi Microlending",
        defaults: UseSmileIDSampleUserDetails(firstName: "Amina", lastName: "Diallo")
      ),
      UseSmileIDSampleProfile(
        id: "p-3",
        organisation: "PesaLink",
        defaults: UseSmileIDSampleUserDetails(firstName: "Tunde", lastName: "Okafor")
      )
    ]
  }
}

public extension UseSmileIDSampleProfiles {
  /// Continue's write-back: the typed details go to the active profile, or become a new active one when there is none. A field the token supplies is never stored, since its value belongs to the token.
  mutating func keep(
    _ details: UseSmileIDSampleUserDetails,
    organisation: String,
    requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement()
  ) {
    let current = active
    let kept = UseSmileIDSampleUserField.allCases.reduce(current?.defaults ?? UseSmileIDSampleUserDetails()) { stored, field in
      requirement.supplies(field) ? stored : field.write(stored, field.read(details))
    }
    if let current {
      update(current.id, defaults: kept)
    } else {
      add(organisation: organisation, defaults: kept, activate: true)
    }
  }
}

/// The stored form of the profiles, one JSON value shared by all four apps so a record reads the same in each.
public enum UseSmileIDSampleProfilesCodec {
  public static let version = 1

  private struct Record: Encodable {
    var version: Int
    var activeId: String?
    var profiles: [UseSmileIDSampleProfile]
  }

  /// Read one profile at a time, so a single bad entry drops that entry rather than every profile.
  private struct StoredRecord: Decodable {
    var version: Int
    var activeId: String?
    var profiles: [Lossy]
  }

  private struct Lossy: Decodable {
    var profile: UseSmileIDSampleProfile?

    init(from decoder: Decoder) throws {
      profile = try? UseSmileIDSampleProfile(from: decoder)
    }
  }

  public static func encode(_ profiles: UseSmileIDSampleProfiles) -> Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    return try? encoder.encode(Record(version: version, activeId: profiles.activeId, profiles: profiles.all))
  }

  /// Anything unreadable, including a version this build does not know, is no profiles: never a crash.
  public static func decode(_ data: Data?) -> UseSmileIDSampleProfiles {
    guard let data, let record = try? JSONDecoder().decode(StoredRecord.self, from: data), record.version == version else {
      return UseSmileIDSampleProfiles()
    }
    let profiles = record.profiles.compactMap(\.profile).filter { !$0.id.isBlank }
    return UseSmileIDSampleProfiles(profiles, activeId: record.activeId)
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
