import Njia
import SampleUI

/// The facts a run of `product` starts with, which the graph's `skipWhen` reads to skip a form.
func useSmileIDSampleFacts(
  _ product: UseSmileIDSampleProduct,
  bindsIdDetails: Bool,
  route: UseSmileIDSampleFlowRoute
) -> Set<UseSmileIDSampleFact> {
  var facts: Set<UseSmileIDSampleFact> = []
  if product == .smartSelfieAuth {
    facts.insert(.needsUserId)
  }
  if product.needsIdDetails, !bindsIdDetails {
    facts.insert(.needsIdDetails)
  }
  if route == .fullscreen {
    facts.insert(.fullScreenRun)
  }
  return facts
}

extension UseSmileIDSampleAppState {
  /// `useSmileIDSampleFacts` for `product` under this launch and its live token.
  func njiaFacts(for product: UseSmileIDSampleProduct) -> Set<UseSmileIDSampleFact> {
    useSmileIDSampleFacts(product, bindsIdDetails: tokenBindsIdDetails(product), route: launchArguments.route)
  }

  /// `firstStep(_:bindsUserDetails:)` under this launch and its live token.
  func njiaFirstStep(in graph: UseSmileIDSampleGraph, for product: UseSmileIDSampleProduct) -> String {
    graph.firstStep(njiaFacts(for: product), bindsUserDetails: tokenBindsUserDetails)
  }
}

/// The wizard's steps in the order `next` walks them: the consent form, the two optional forms and the run's two forms.
private let wizard: [UseSmileIDSampleStep] = [.consentDetailsForm, .authUserId, .idDetailsForm, .sdkFlow, .sdkFlowFullScreen]

extension NjiaGraph where K == UseSmileIDSampleStep, F == UseSmileIDSampleFact {
  /// Where a product tap goes: the consent form unless the token binds user details, else the first wizard step `facts` don't skip.
  func firstStep(_ facts: Set<UseSmileIDSampleFact>, bindsUserDetails: Bool) -> String {
    let kinds = wizard.dropFirst(bindsUserDetails ? 1 : 0)
    let first = kinds
      .compactMap { kind in steps.first { $0.kind == kind } }
      .first { $0.skipWhen?.holdsFor(facts) != true }
    guard let first else { preconditionFailure("the graph's wizard skips every step") }
    return first.id
  }
}
