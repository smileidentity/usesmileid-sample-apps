import Foundation

/// How long a simulated token lasts: the three live spans are the Portal's allow-list, and `ended` reaches the expiry gate without waiting.
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

/// What a simulated token binds, both off by default: a binding removes a screen at runtime, so it must be asked for.
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
