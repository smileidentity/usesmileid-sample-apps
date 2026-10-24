import Foundation
import SampleUI

/// Where a run starts: the facts it runs under and the step a product tap goes to.
struct UseSmileIDSampleRunEntry: Equatable {
  let facts: Set<UseSmileIDSampleFact>
  let step: String
}

extension UseSmileIDSampleAppState {
  /// A product tap's run, or nil when no live session backs it and the scanner comes first, since every run submits under a token.
  func entry(in graph: UseSmileIDSampleGraph, for product: UseSmileIDSampleProduct) -> UseSmileIDSampleRunEntry? {
    guard let session, !session.hasExpired(at: Date()) else {
      interruptedRun = UseSmileIDSampleRunIntent(productId: product.id, route: launchArguments.route, resumeAt: .firstStep)
      return nil
    }
    return runEntry(in: graph, for: product)
  }

  /// Where `product` starts under this launch and its token: a form is skipped only when the token already carries all of it.
  func runEntry(in graph: UseSmileIDSampleGraph, for product: UseSmileIDSampleProduct) -> UseSmileIDSampleRunEntry {
    UseSmileIDSampleRunEntry(facts: njiaFacts(for: product), step: njiaFirstStep(in: graph, for: product))
  }

  /// Straight into the run on `route`, past every form, as an autostart or a resumed run goes.
  func runOnly(_ product: UseSmileIDSampleProduct, route: UseSmileIDSampleFlowRoute) -> UseSmileIDSampleRunEntry {
    UseSmileIDSampleRunEntry(
      facts: useSmileIDSampleFacts(product, bindsIdDetails: tokenBindsIdDetails(product), route: route),
      step: (route == .fullscreen ? UseSmileIDSampleStep.sdkFlowFullScreen : .sdkFlow).rawValue
    )
  }
}
