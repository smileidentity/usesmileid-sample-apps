/// The ID-details form. ID type stays unselectable until a country is chosen.
public struct UseSmileIDSampleIdDetails: Equatable, Sendable {
  public var country: UseSmileIDSampleCountry?
  public var idType: UseSmileIDSampleIdType?
  public var idNumber: String

  public init(
    country: UseSmileIDSampleCountry? = nil,
    idType: UseSmileIDSampleIdType? = nil,
    idNumber: String = ""
  ) {
    self.country = country
    self.idType = idType
    self.idNumber = idNumber
  }

  public var isComplete: Bool {
    country != nil && idType != nil && !idNumber.isBlank
  }
}

/// A country the sandbox supports, with the flag the picker leads each row with.
public enum UseSmileIDSampleCountry: String, CaseIterable, Sendable {
  case nigeria = "NG"
  case kenya = "KE"
  case ghana = "GH"
  case southAfrica = "ZA"
  case uganda = "UG"
  case tanzania = "TZ"
  case rwanda = "RW"

  public var code: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .nigeria: "Nigeria"
    case .kenya: "Kenya"
    case .ghana: "Ghana"
    case .southAfrica: "South Africa"
    case .uganda: "Uganda"
    case .tanzania: "Tanzania"
    case .rwanda: "Rwanda"
    }
  }

  public var flag: String {
    switch self {
    case .nigeria: "\u{1F1F3}\u{1F1EC}"
    case .kenya: "\u{1F1F0}\u{1F1EA}"
    case .ghana: "\u{1F1EC}\u{1F1ED}"
    case .southAfrica: "\u{1F1FF}\u{1F1E6}"
    case .uganda: "\u{1F1FA}\u{1F1EC}"
    case .tanzania: "\u{1F1F9}\u{1F1FF}"
    case .rwanda: "\u{1F1F7}\u{1F1FC}"
    }
  }
}

/// ID types, filtered by country, which is why the trigger is disabled until one is chosen.
public enum UseSmileIDSampleIdType: String, CaseIterable, Sendable {
  case nationalId = "NATIONAL_ID"
  case passport = "PASSPORT"
  case driversLicense = "DRIVERS_LICENSE"
  case voterId = "VOTER_ID"

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .nationalId: "National ID"
    case .passport: "Passport"
    case .driversLicense: "Driver's licence"
    case .voterId: "Voter ID"
    }
  }

  public var countries: Set<UseSmileIDSampleCountry> {
    switch self {
    case .nationalId, .passport: Set(UseSmileIDSampleCountry.allCases)
    case .driversLicense: [.nigeria, .kenya, .southAfrica]
    case .voterId: [.nigeria, .ghana]
    }
  }

  public static func of(_ country: UseSmileIDSampleCountry?) -> [UseSmileIDSampleIdType] {
    guard let country else { return [] }
    return allCases.filter { $0.countries.contains(country) }
  }

  public static func of(_ country: UseSmileIDSampleCountry?, matching query: String) -> [UseSmileIDSampleIdType] {
    of(country).filter { $0.label.matches(query) }
  }
}

public extension UseSmileIDSampleCountry {
  static func matching(_ query: String) -> [UseSmileIDSampleCountry] {
    allCases.filter { $0.label.matches(query) }
  }
}

extension String {
  /// An empty query matches everything. `localizedCaseInsensitiveContains("")` answers false, where
  /// the Compose twin's `contains("")` answers true — so a literal port opens both pickers empty.
  func matches(_ query: String) -> Bool {
    query.isBlank || localizedCaseInsensitiveContains(query)
  }
}
