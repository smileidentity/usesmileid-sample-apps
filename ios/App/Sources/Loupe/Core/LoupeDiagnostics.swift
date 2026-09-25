import Foundation

/// Counts what the loupe was offered and what it turned away, so a missing request can be located.
///
/// Three numbers separate the three ways a call goes unrecorded: a session that was never
/// instrumented offers nothing, so `offered` stays flat; a request the protocol declined shows in
/// `declined` with its reason; and anything else means the exchange was taken but the record never
/// arrived. Guessing between those from the outside is what this replaces.
///
/// Lock-guarded because `canInit` runs on the loading system's threads.
final class LoupeDiagnostics: @unchecked Sendable {
  static let shared = LoupeDiagnostics()

  struct Snapshot {
    var instrumentedSessions = 0
    var offered = 0
    var declined = 0
    /// The most recent refusals, newest first, each as "reason — host".
    var reasons: [String] = []
  }

  private let lock = NSLock()
  private var snapshot = Snapshot()

  var current: Snapshot {
    lock.lock()
    defer { lock.unlock() }
    return snapshot
  }

  func countInstrumentedSession() {
    mutate { $0.instrumentedSessions += 1 }
  }

  func countOffered() {
    mutate { $0.offered += 1 }
  }

  func countDeclined(_ reason: String, host: String) {
    mutate {
      $0.declined += 1
      $0.reasons.insert("\(reason) — \(host)", at: 0)
      if $0.reasons.count > 10 {
        $0.reasons.removeLast()
      }
    }
  }

  func reset() {
    mutate { $0 = Snapshot() }
  }

  private func mutate(_ change: (inout Snapshot) -> Void) {
    lock.lock()
    defer { lock.unlock() }
    change(&snapshot)
  }
}
