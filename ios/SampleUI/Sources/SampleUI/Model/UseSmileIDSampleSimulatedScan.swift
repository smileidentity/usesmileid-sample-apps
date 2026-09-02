import Foundation

/// How long a simulated scan's token lasts. The three live spans are the Portal's own expiry
/// allow-list; `ended` is the only way a device flow can reach the expiry gate without waiting.
public enum UseSmileIDSampleSimulatedSpan: String, CaseIterable, Sendable {
  case fifteenMinutes
  case oneHour
  case eightHours
  case ended

  public var label: String {
    switch self {
    case .fifteenMinutes: "15m"
    case .oneHour: "1h"
    case .eightHours: "8h"
    case .ended: "Expired"
    }
  }

  public var span: TimeInterval {
    switch self {
    case .fifteenMinutes, .ended: 15 * 60
    case .oneHour: 60 * 60
    case .eightHours: 8 * 60 * 60
    }
  }

  public var isEnded: Bool {
    self == .ended
  }
}

/// What a simulated scan's token binds. Both default to off, so a simulated session never silently
/// changes the screen set: a bound consent removes the SDK's consent screen at runtime, and bound
/// details carry the ID parameters too, which removes the host's own ID form.
public struct UseSmileIDSampleSimulatedBindings: Equatable, Sendable {
  public var consent: Bool
  public var userDetails: Bool

  public init(consent: Bool = false, userDetails: Bool = false) {
    self.consent = consent
    self.userDetails = userDetails
  }

  public var binds: Bool {
    consent || userDetails
  }
}
