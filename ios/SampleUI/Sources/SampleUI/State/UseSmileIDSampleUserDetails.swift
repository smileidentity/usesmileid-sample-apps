import Foundation

/// The fields the design labels "attached to every job", which is why every product collects them.
public struct UseSmileIDSampleUserDetails: Equatable, Sendable {
  public var firstName: String
  public var lastName: String
  public var email: String
  public var phone: String

  public init(firstName: String = "", lastName: String = "", email: String = "", phone: String = "") {
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.phone = phone
  }

  /// The design's own rule: "First and last name are required."
  public var isComplete: Bool {
    !firstName.isBlank && !lastName.isBlank
  }

  /// Whether the form has collected what `requirement` still asks of it.
  public func satisfies(_ requirement: UseSmileIDSampleUserDetailsRequirement) -> Bool {
    (!requirement.firstName || !firstName.isBlank)
      && (!requirement.lastName || !lastName.isBlank)
      && (!requirement.contact || !email.isBlank || !phone.isBlank)
  }
}

/// What the form must still collect: the SDK's rule minus what the token binds.
public struct UseSmileIDSampleUserDetailsRequirement: Equatable, Sendable {
  public var firstName: Bool
  public var lastName: Bool
  public var contact: Bool

  public init(firstName: Bool = true, lastName: Bool = true, contact: Bool = true) {
    self.firstName = firstName
    self.lastName = lastName
    self.contact = contact
  }

  /// Nothing left to ask, so the form has no reason to appear.
  public var isSatisfied: Bool {
    !firstName && !lastName && !contact
  }

  /// No relevant binding at all, the one case the SDK's own validator can still decide.
  public var bindsNothing: Bool {
    firstName && lastName && contact
  }

  /// Whether the token already supplied `field`, which is why it renders as provided.
  public func supplies(_ field: UseSmileIDSampleUserField) -> Bool {
    switch field {
    case .firstName: !firstName
    case .lastName: !lastName
    // The rule is "one of", so a bound email leaves phone askable. Only the requirement lifts.
    case .email, .phone: false
    }
  }

  /// A contact row stops saying "optional" the moment one of the two is actually required.
  public func label(for field: UseSmileIDSampleUserField) -> String {
    guard contact else { return field.label }
    switch field {
    case .email: return "Email"
    case .phone: return "Phone"
    default: return field.label
    }
  }

  /// The sentence under the form, which has to name what is actually outstanding.
  public var prompt: String {
    var outstanding: [String] = []
    if firstName {
      outstanding.append("first name")
    }
    if lastName {
      outstanding.append("last name")
    }
    if contact {
      outstanding.append("an email or phone number")
    }
    switch outstanding.count {
    case 0: return "Tap any field to edit."
    case 1: return outstanding[0].prefix(1).uppercased() + outstanding[0].dropFirst() + " is required."
    default: return "Required: " + outstanding.joined(separator: ", ") + "."
    }
  }
}

public extension UseSmileIDSampleUserDetailsRequirement {
  /// What a token leaves the form to collect, mirroring the SDK's union rule: both names plus one contact field.
  init(bindings: UseSmileIDSampleTokenBindings?) {
    self.init(
      firstName: bindings?.givenNames != true,
      lastName: bindings?.lastName != true,
      contact: !(bindings?.email == true || bindings?.phoneNumber == true)
    )
  }
}

/// Which user-details row changed, so the form reports one callback rather than four.
public enum UseSmileIDSampleUserField: String, CaseIterable, Sendable {
  case firstName
  case lastName
  case email
  case phone

  public var id: String {
    rawValue
  }

  public var label: String {
    switch self {
    case .firstName: "First name"
    case .lastName: "Last name"
    case .email: "Email (optional)"
    case .phone: "Phone (optional)"
    }
  }

  public var placeholder: String {
    switch self {
    case .firstName: "Add first name"
    case .lastName: "Add last name"
    case .email: "name@company.com"
    case .phone: "+254 700 000 000"
    }
  }

  public var required: Bool {
    self == .firstName || self == .lastName
  }

  public func read(_ details: UseSmileIDSampleUserDetails) -> String {
    switch self {
    case .firstName: details.firstName
    case .lastName: details.lastName
    case .email: details.email
    case .phone: details.phone
    }
  }

  public func write(_ details: UseSmileIDSampleUserDetails, _ value: String) -> UseSmileIDSampleUserDetails {
    var next = details
    switch self {
    case .firstName: next.firstName = value
    case .lastName: next.lastName = value
    case .email: next.email = value
    case .phone: next.phone = value
    }
    return next
  }
}

extension String {
  /// Whitespace-only counts as missing: a space is not a first name.
  var isBlank: Bool {
    trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
