import Foundation
import SampleUI
import UseSmileID

/// The session a run actually submits under. Absent for the two scenarios that are *about* refresh:
/// a scanned token has no refresh journey, and the fixtures are what keep those scenarios meaningful.
extension FlowLaunchSnapshot {
  var liveSession: UseSmileIDSampleTokenSession? {
    scenario.startsExpired ? nil : session
  }
}

extension UseSmileIDSampleScenario {
  var startsExpired: Bool {
    self == .expiredToken || self == .badRefresh
  }
}

/// The live-session rule, in one place, so nothing disagrees about whether a token is live.
extension UseSmileIDSampleTokenSession {
  func live(for scenario: UseSmileIDSampleScenario, at now: Date) -> UseSmileIDSampleTokenSession? {
    hasExpired(at: now) || scenario.startsExpired ? nil : self
  }
}

extension UseSmileIDSampleAppState {
  func liveSession(at now: Date) -> UseSmileIDSampleTokenSession? {
    session?.live(for: flowResult.scenario, at: now)
  }

  /// The bindings a run may read, or nil when no live token backs it. Read through the same rule the
  /// gate uses, so a skipped form can never be followed by a redirect back to it.
  var liveBindings: UseSmileIDSampleTokenBindings? {
    liveSession(at: now)?.bindings
  }

  /// Whether the token this run will submit under binds the user details the SDK requires — both
  /// names plus one contact field. When it does the SDK asks nothing more of `userDetails`, so the
  /// host's own form has nothing left to collect and the journey may start past it.
  var tokenBindsUserDetails: Bool {
    liveBindings?.bindsRequiredUserDetails == true
  }

  func tokenBindsIdDetails(_ product: UseSmileIDSampleProduct) -> Bool {
    liveBindings?.bindsIdDetails(product) == true
  }
}

/// Drops the issues the token already answers; every other rule the SDK applies still stands.
func useSmileIDSampleOutstanding(
  _ state: ValidationState,
  _ requirement: UseSmileIDSampleUserDetailsRequirement
) -> ValidationState {
  guard case .invalid(let issues) = state else { return state }
  let outstanding = issues.filter { !requirement.covers($0) }
  return outstanding.isEmpty ? .valid : .invalid(outstanding)
}

private extension UseSmileIDSampleUserDetailsRequirement {
  func covers(_ issue: any UseSmileIDValidationException) -> Bool {
    guard let field = issue as? InvalidFieldValueException else { return false }
    switch field.fieldName {
    case "userDetails.givenNames": return !firstName
    case "userDetails.lastName": return !lastName
    // The contact rule is reported against the object rather than a field, so the reason is what
    // identifies it — anything else raised at that level is not ours to drop.
    case "userDetails": return !contact && field.reason.range(of: "email", options: .caseInsensitive) != nil
    default: return false
    }
  }
}
