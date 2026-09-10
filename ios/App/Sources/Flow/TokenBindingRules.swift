import Foundation
import SampleUI
import UseSmileID

/// The session a run submits under, absent for the two scenarios that are about refresh.
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

extension UseSmileIDSampleTokenSession {
  func live(for scenario: UseSmileIDSampleScenario, at now: Date) -> UseSmileIDSampleTokenSession? {
    hasExpired(at: now) || scenario.startsExpired ? nil : self
  }
}

extension UseSmileIDSampleAppState {
  func liveSession(at now: Date) -> UseSmileIDSampleTokenSession? {
    session?.live(for: flowResult.scenario, at: now)
  }

  /// Read through the gate's own rule, so a skipped form is never followed by a redirect back to it.
  var liveBindings: UseSmileIDSampleTokenBindings? {
    liveSession(at: now)?.bindings
  }

  /// Both names plus one contact field: with those bound the form has nothing left to collect.
  var tokenBindsUserDetails: Bool {
    liveBindings?.bindsRequiredUserDetails == true
  }

  func tokenBindsIdDetails(_ product: UseSmileIDSampleProduct) -> Bool {
    liveBindings?.bindsIdDetails(product) == true
  }
}

/// Drops the issues the token answers; every other rule the SDK applies still stands.
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
    // Reported against the object rather than a field, so the reason is what identifies it.
    case "userDetails": return !contact && field.reason.range(of: "email", options: .caseInsensitive) != nil
    default: return false
    }
  }
}
