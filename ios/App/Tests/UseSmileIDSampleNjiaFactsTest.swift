import Njia
import SampleUI
@testable import UseSmileIDSample
import XCTest

/// njia's wizard, driven by the app's facts, walks the same forms the shell's journey rules pick.
final class UseSmileIDSampleNjiaFactsTest: XCTestCase {
  /// The wizard has five steps, so a longer walk is a loop.
  private static let runLength = 5

  func testEveryProductWalksTheFormsItsTokenLeavesThenTheRunItsLaunchAskedFor() throws {
    let graph = try UseSmileIDSampleNjiaSpec.graph()
    for product in UseSmileIDSampleProduct.allCases {
      for bindsUser in [false, true] {
        for bindsId in [false, true] {
          for route in UseSmileIDSampleFlowRoute.allCases {
            XCTAssertEqual(
              try walked(graph, product, bindsUser: bindsUser, bindsId: bindsId, route: route),
              expected(product, bindsUser: bindsUser, bindsId: bindsId, route: route),
              "\(product) binds user \(bindsUser) id \(bindsId) \(route)"
            )
          }
        }
      }
    }
  }

  func testFactsNameOnlyWhatARunNeeds() {
    XCTAssertEqual(useSmileIDSampleFacts(.smartSelfieEnrollment, bindsIdDetails: false, route: .shell), [])
    XCTAssertEqual(useSmileIDSampleFacts(.smartSelfieAuth, bindsIdDetails: false, route: .fullscreen), [.needsUserId, .fullScreenRun])
  }

  /// The shell's journey rules: consent unless bound, the auth user ID, ID details unless bound, then the run.
  private func expected(
    _ product: UseSmileIDSampleProduct,
    bindsUser: Bool,
    bindsId: Bool,
    route: UseSmileIDSampleFlowRoute
  ) -> [UseSmileIDSampleStep] {
    var steps: [UseSmileIDSampleStep] = bindsUser ? [] : [.consentDetailsForm]
    if product == .smartSelfieAuth {
      steps.append(.authUserId)
    } else if product.needsIdDetails, !bindsId {
      steps.append(.idDetailsForm)
    }
    steps.append(route == .fullscreen ? .sdkFlowFullScreen : .sdkFlow)
    return steps
  }

  /// A product tap from the products tab, then `next` from each form until the run is on top.
  private func walked(
    _ graph: UseSmileIDSampleGraph,
    _ product: UseSmileIDSampleProduct,
    bindsUser: Bool,
    bindsId: Bool,
    route: UseSmileIDSampleFlowRoute
  ) throws -> [UseSmileIDSampleStep] {
    let facts = useSmileIDSampleFacts(product, bindsIdDetails: bindsId, route: route)
    let engine = try NjiaKit.start(graph, facts: facts)
    let tab = try XCTUnwrap(engine.top)
    engine.navigator(tab).go(graph.firstStep(facts, bindsUserDetails: bindsUser), arg: product.id)
    var walked: [UseSmileIDSampleStep] = []
    while let top = engine.top {
      let kind = engine.stepOf(top).kind
      walked.append(kind)
      if kind == .sdkFlow || kind == .sdkFlowFullScreen || walked.count > Self.runLength {
        break
      }
      engine.next(top)
    }
    return walked
  }
}
