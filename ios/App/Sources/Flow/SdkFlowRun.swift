import Foundation
import SampleUI
import UseSmileID

/// One run's identity, created once per flow entry.
///
/// The Compose twin's `SdkFlowViewModel` minus its saved state: nothing here survives process death,
/// because the SDK's own manager is a `@StateObject` that goes with the scene.
@MainActor
final class SdkFlowRun: ObservableObject {
  enum Stage: Equatable {
    case entering
    case ready
    /// The gate refused, or a result landed, so the route must mount nothing.
    case left
  }

  @Published private(set) var stage: Stage = .entering

  /// Held rather than rebuilt: `UseSmileIDBuilder.init` applies the configuration eagerly, and the
  /// host re-renders once a second while a session is live.
  private(set) var builder: UseSmileIDBuilder?

  /// Non-nil only while the run is mounted, which is when a camera hold is worth taking.
  private(set) var product: UseSmileIDSampleProduct?

  private var entered = false

  /// True once per entry: the level re-appears, and the gate must not run again.
  func claimEntry() -> Bool {
    guard !entered else { return false }
    entered = true
    return true
  }

  func start(product: UseSmileIDSampleProduct, builder: UseSmileIDBuilder) {
    self.product = product
    self.builder = builder
    stage = .ready
  }

  func leave() {
    builder = nil
    product = nil
    stage = .left
  }
}
