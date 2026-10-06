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

  /// Whether the form has collected what `requirement` still asks of it, in a form the server accepts.
  public func satisfies(_ requirement: UseSmileIDSampleUserDetailsRequirement) -> Bool {
    (!requirement.firstName || !firstName.isBlank)
      && (!requirement.lastName || !lastName.isBlank)
      && (!requirement.contact || !email.isBlank || !phone.isBlank)
      && contactProblem == nil
  }

  /// Why the email or phone would fail the job, email first; nil when both would pass.
  public var contactProblem: String? {
    UseSmileIDSampleContactRules.problem(.email, email) ?? UseSmileIDSampleContactRules.problem(.phone, phone)
  }

  /// The email as the server wants it, or nil when blank.
  public var submittedEmail: String? {
    UseSmileIDSampleContactRules.submitted(.email, email).nilIfEmpty
  }

  /// The phone number as the server wants it, or nil when blank.
  public var submittedPhone: String? {
    UseSmileIDSampleContactRules.submitted(.phone, phone).nilIfEmpty
  }
}

/// The email and phone checks from `spec/contact-rules.json`, which mirror the v3 API's own request schema.
public enum UseSmileIDSampleContactRules {
  public static var emailError: String {
    UseSmileIDSampleStrings.userFieldEmailError
  }

  public static var phoneError: String {
    UseSmileIDSampleStrings.userFieldPhoneError
  }

  /// `value` as it is submitted: trimmed, and a phone number without its separators.
  public static func submitted(_ field: UseSmileIDSampleUserField, _ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard field == .phone else { return trimmed }
    return trimmed.replacingOccurrences(of: "[\\s().-]", with: "", options: .regularExpression)
  }

  /// Why `value` would fail the job as `field`, or nil when it would pass; blank always passes.
  public static func problem(_ field: UseSmileIDSampleUserField, _ value: String) -> String? {
    let submitted = submitted(field, value)
    guard !submitted.isEmpty else { return nil }
    switch field {
    case .email: return matches(submitted, "^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$") ? nil : emailError
    case .phone: return matches(submitted, "^\\+[1-9][0-9]{6,14}$") ? nil : phoneError
    default: return nil
    }
  }

  private static func matches(_ value: String, _ pattern: String) -> Bool {
    value.range(of: pattern, options: .regularExpression) != nil
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
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
    case .email: return UseSmileIDSampleStrings.userFieldEmail
    case .phone: return UseSmileIDSampleStrings.userFieldPhone
    default: return field.label
    }
  }

  /// The sentence under the form, which has to name what is actually outstanding.
  public var prompt: String {
    var outstanding: [String] = []
    if firstName {
      outstanding.append(UseSmileIDSampleStrings.userRequirementFirstName)
    }
    if lastName {
      outstanding.append(UseSmileIDSampleStrings.userRequirementLastName)
    }
    if contact {
      outstanding.append(UseSmileIDSampleStrings.userRequirementContact)
    }
    switch outstanding.count {
    case 0: return UseSmileIDSampleStrings.userDetailsEditHint
    case 1: return Self.sentence(UseSmileIDSampleStrings.userRequirementOne(field: outstanding[0]))
    default: return Self.sentence(UseSmileIDSampleStrings.userRequirementMany(fields: outstanding.joined(separator: UseSmileIDSampleStrings.userRequirementSeparator)))
    }
  }

  /// The prompt opens a sentence, so its first letter is capitalised.
  private static func sentence(_ text: String) -> String {
    text.prefix(1).uppercased() + text.dropFirst()
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
    case .firstName: UseSmileIDSampleStrings.userFieldFirstName
    case .lastName: UseSmileIDSampleStrings.userFieldLastName
    case .email: UseSmileIDSampleStrings.userFieldEmailOptional
    case .phone: UseSmileIDSampleStrings.userFieldPhoneOptional
    }
  }

  public var placeholder: String {
    switch self {
    case .firstName: UseSmileIDSampleStrings.userFieldFirstNamePlaceholder
    case .lastName: UseSmileIDSampleStrings.userFieldLastNamePlaceholder
    case .email: UseSmileIDSampleStrings.userFieldEmailPlaceholder
    case .phone: UseSmileIDSampleStrings.userFieldPhonePlaceholder
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
