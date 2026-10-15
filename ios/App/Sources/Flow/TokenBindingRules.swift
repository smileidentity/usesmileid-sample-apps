import Foundation
import SampleUI
import UseSmileID

/// The session a run submits under, absent for the two scenarios that are about refresh.
extension FlowLaunchSnapshot {
  var liveSession: UseSmileIDSampleTokenSession? {
    scenario.startsExpired ? nil : session
  }

  /// Dropped under a live session, as the partner id already is: the token's partner owns the job.
  var resolvedCallbackUrl: String {
    liveSession != nil ? "" : callbackUrl
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
