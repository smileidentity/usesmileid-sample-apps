import Foundation
import SampleUI
import UseSmileID

/// One run's identity, created once per flow entry.
///
/// The Compose twin's `SdkFlowViewModel`, without its `SavedStateHandle`: iOS has no
/// per-back-stack-entry ViewModel, `port-patterns.md` §2 puts screen state in a holder beside the
/// screen, and what Android's saved state buys — a run that survives process death — is deliberately
/// absent here. `ios-port-hardening.md` §10 ruled every launch a fresh run, and the SDK's own
/// `FlowNavigationManager` is a `@StateObject`, so a killed scene takes the run with it and there is
/// no buffered result left to orphan.
@MainActor
final class SdkFlowRun: ObservableObject {
  /// Where the entry has reached. The gate runs when the push has landed, not in `onAppear`: UIKit
  /// drops a pop made mid-transition, and the SDK should not start under a running animation either.
  enum Stage: Equatable {
    case entering
    case ready
    /// The gate refused, or a result landed: the route is leaving and must mount nothing.
    case left
  }

  @Published private(set) var stage: Stage = .entering

  /// Built once and held, because `UseSmileIDBuilder.init` applies the configuration eagerly — a
  /// rebuild per render would allocate a network client and an ML registry every time, and the host
  /// re-renders once a second while a token session is live.
  private(set) var builder: UseSmileIDBuilder?

  private var entered = false

  /// True exactly once per entry, so the gate cannot run twice when the level re-appears.
  func claimEntry() -> Bool {
    guard !entered else { return false }
    entered = true
    return true
  }

  func start(builder: UseSmileIDBuilder) {
    self.builder = builder
    stage = .ready
  }

  /// The gate refused the run, or a result has landed and the route is being replaced.
  func leave() {
    builder = nil
    stage = .left
  }
}
