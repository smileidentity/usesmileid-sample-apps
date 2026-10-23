import Foundation
import Njia
import NjiaUI
import SampleUI

/// The shell's engine, over the app's own step kinds and facts.
typealias UseSmileIDSampleEngine = NjiaEngine<UseSmileIDSampleStep, UseSmileIDSampleFact>

/// What each of the app's steps sees of the flow.
typealias UseSmileIDSampleStepScope = NjiaStepScope<UseSmileIDSampleStep, UseSmileIDSampleFact>

/// Holds the shell's engine and publishes its state, which `@SceneStorage` keeps so a relaunch restores the stack.
@MainActor
final class UseSmileIDSampleNavigationModel: ObservableObject {
  let graph: UseSmileIDSampleGraph

  @Published private(set) var engine: UseSmileIDSampleEngine
  @Published private(set) var state: NjiaState<UseSmileIDSampleFact>

  /// On a cold start a link and a restore race; whichever lands first wins.
  private(set) var hasOpened = false
  private var listening: NjiaListenerToken?

  init(graph: UseSmileIDSampleGraph = Bundle.main.useSmileIDSampleNjiaGraph()) {
    self.graph = graph
    let engine = Self.started(graph)
    self.engine = engine
    state = engine.state
    watch(engine)
  }

  /// Opens `link` under `facts` as a new flow; a link the graph refuses leaves the current one.
  @discardableResult
  func open(_ link: String, facts: Set<UseSmileIDSampleFact>) -> Bool {
    hasOpened = true
    guard let next = try? NjiaKit.openLink(graph, link: link, facts: facts) else { return false }
    replace(keepingOtherTabs(of: state, under: next))
    return true
  }

  /// `next`, with the stacks `previous` held on the tabs the link didn't open, so switching back finds them as they were.
  private func keepingOtherTabs(of previous: NjiaState<UseSmileIDSampleFact>, under next: UseSmileIDSampleEngine) -> UseSmileIDSampleEngine {
    guard let previousTab = previous.entries.first?.step, let openedTab = next.state.entries.first?.step else { return next }
    var stacks = previous.parked
    stacks[previousTab] = Array(previous.entries.dropFirst())
    var merged = next.state
    // A run isn't kept: parked, its entry takes a new id, so its result would find nothing to leave and a second run would start.
    for (tab, stack) in stacks where tab != openedTab && merged.parked[tab] == nil && !stack.isEmpty
      && !stack.contains(where: { [.sdkFlow, .sdkFlowFullScreen].contains(graph.stepOf($0).kind) }) {
      // Renumbered above the link's own entries, since ids are never reused within a flow.
      merged.parked[tab] = stack.map { entry in
        defer { merged.nextId += 1 }
        return NjiaEntry(id: merged.nextId, step: entry.step, visit: entry.visit, answer: entry.answer, arg: entry.arg)
      }
    }
    return (try? NjiaKit.restore(graph, state: merged)) ?? next
  }

  /// A fresh flow on the products tab.
  func restart() {
    replace(Self.started(graph))
  }

  /// Unreadable state, or a state an updated graph no longer fits, keeps the fresh flow rather than throwing into a blank window.
  func restore(from encoded: String) {
    guard !hasOpened else { return }
    hasOpened = true
    guard !encoded.isEmpty,
          let saved = try? useSmileIDSampleNjiaCodec.decodeState(encoded),
          let next = try? NjiaKit.restore(graph, state: saved)
    else { return }
    replace(next)
  }

  func encodedState() -> String {
    useSmileIDSampleNjiaCodec.encodeState(state)
  }

  private func replace(_ next: UseSmileIDSampleEngine) {
    listening.map(engine.removeListener)
    engine = next
    state = next.state
    watch(next)
  }

  private func watch(_ engine: UseSmileIDSampleEngine) {
    listening = engine.addListener { [weak self] transition in
      MainActor.assumeIsolated { self?.state = transition.state }
    }
  }

  /// The graph is the app's own, checked by its tests, so a refusal to start it is a broken build.
  private static func started(_ graph: UseSmileIDSampleGraph) -> UseSmileIDSampleEngine {
    guard let engine = try? NjiaKit.start(graph) else { preconditionFailure("njia refused the app's graph") }
    return engine
  }
}

/// The wizard's step kinds, which a run's product is read through.
private let runSteps: Set<UseSmileIDSampleStep> = [.consentDetailsForm, .authUserId, .idDetailsForm, .sdkFlow, .sdkFlowFullScreen]

extension NjiaEngine where K == UseSmileIDSampleStep, F == UseSmileIDSampleFact {
  /// The entry a run started at: the nearest wizard entry at or below `entry` that carries the product.
  func runStart(_ entry: NjiaEntry) -> NjiaEntry? {
    guard let at = state.entries.firstIndex(where: { $0.id == entry.id }) else { return nil }
    return state.entries[...at].last { $0.arg != nil && runSteps.contains(stepOf($0).kind) }
  }

  /// The product the run `entry` belongs to, read from the run's first entry.
  func runProductId(_ entry: NjiaEntry) -> String? {
    runStart(entry)?.arg
  }

  /// Starts a run of `product` from `from`, in place of `replace` if given: sets the run's facts, clears the rest, then goes to its first step carrying the product.
  func startRun(from: NjiaEntry, product: UseSmileIDSampleProduct, run: UseSmileIDSampleRunEntry, replace: Int64? = nil) {
    send(.facts(set: Array(run.facts), clear: UseSmileIDSampleFact.allCases.filter { !run.facts.contains($0) }))
    navigator(from).go(run.step, arg: product.id, replace: replace)
  }

  /// Leaves the run `entry` belongs to by going to `step` in its place, with `arg`.
  func leaveRun(_ entry: NjiaEntry, to step: UseSmileIDSampleStep, arg: String? = nil) {
    let start = runStart(entry) ?? entry
    navigator(entry).go(step.rawValue, arg: arg, replace: start.id)
  }

  /// Back to the products tab's root, which leaves a run however deep it went.
  func leaveToProducts() {
    select(UseSmileIDSampleStep.products.rawValue)
  }
}

extension NjiaNavigator {
  /// Goes to `step` carrying `arg`: every step's id is its kind's wire name, which the routes test pins.
  func go(_ step: UseSmileIDSampleStep, arg: String? = nil) {
    go(step.rawValue, arg: arg)
  }
}
