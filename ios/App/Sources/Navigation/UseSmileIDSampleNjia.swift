import Foundation
import Njia

/// What a step of `spec/njia-graph.json` shows: its `kind`, named as the graph names it.
enum UseSmileIDSampleStep: String, CaseIterable {
  case products
  case verifications
  case settings
  case licenses
  case captureMode
  case appearance
  case language
  case scenarioDrawer
  case verificationDetails
  case profileSwitch
  case profiles
  case newProfile
  case profileConfig
  case scanToken
  case countryPicker
  case idTypePicker
  case documentPicker
  case captureAs
  case genericDocument
  case consentDetailsForm
  case authUserId
  case idDetailsForm
  case sdkFlow
  case sdkFlowFullScreen
}

/// What a run's product, token and launch say about it: the facts the graph's `skipWhen` reads.
enum UseSmileIDSampleFact: String, CaseIterable {
  /// SmartSelfie Authentication, which asks for the user ID to authenticate.
  case needsUserId
  /// A product that needs ID details the token doesn't already bind.
  case needsIdDetails
  /// The run was launched full screen, over the tab bar.
  case fullScreenRun
}

/// The app's graph, read with its own kinds and facts.
typealias UseSmileIDSampleGraph = NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>

/// Reads the graph with the app's own kinds and facts, so one the app doesn't know fails to decode.
var useSmileIDSampleNjiaCodec: NjiaCodec<UseSmileIDSampleStep, UseSmileIDSampleFact> {
  NjiaCodec(kinds: .enum(), facts: .enum())
}

/// The graph's file name, which the build bundles from `spec/` under the same name.
let useSmileIDSampleNjiaGraphFile = "njia-graph.json"

extension Bundle {
  /// The four apps' one navigation graph, as this build bundles it; a missing or unreadable graph is a broken build.
  func useSmileIDSampleNjiaGraph() -> UseSmileIDSampleGraph {
    guard let url = url(forResource: useSmileIDSampleNjiaGraphFile, withExtension: nil),
          let text = try? String(contentsOf: url, encoding: .utf8),
          let graph = try? useSmileIDSampleNjiaCodec.decodeGraph(text)
    else { preconditionFailure("the build bundles no readable \(useSmileIDSampleNjiaGraphFile)") }
    return graph
  }
}
