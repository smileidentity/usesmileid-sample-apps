import Foundation
@testable import SampleUI
import XCTest

/// For the tests that never refresh: reaching the network from one of them is the failure, not a fixture.
struct UseSmileIDSampleUnreachableStatusSource: UseSmileIDSampleJobStatusSource {
  func check(jobId _: String, token _: String, sandbox _: Bool) async throws -> UseSmileIDSampleStatusRefresh {
    XCTFail("a test with no refresh asked the network")
    return .failed(reason: "unreachable")
  }
}

/// Records what the store asked for, which is the point of most of the refresh table.
final class UseSmileIDSampleFakeStatusSource: UseSmileIDSampleJobStatusSource, @unchecked Sendable {
  struct Call: Equatable {
    let jobId: String
    let token: String
    let sandbox: Bool
  }

  private let lock = NSLock()
  private var recorded: [Call] = []
  private var answer: @Sendable (Call) async throws -> UseSmileIDSampleStatusRefresh

  init(answer: @escaping @Sendable (Call) async throws -> UseSmileIDSampleStatusRefresh) {
    self.answer = answer
  }

  var calls: [Call] {
    lock.withLock { recorded }
  }

  func answer(with answer: @escaping @Sendable (Call) async throws -> UseSmileIDSampleStatusRefresh) {
    lock.withLock { self.answer = answer }
  }

  func check(jobId: String, token: String, sandbox: Bool) async throws -> UseSmileIDSampleStatusRefresh {
    let call = Call(jobId: jobId, token: token, sandbox: sandbox)
    let answer = lock.withLock {
      recorded.append(call)
      return self.answer
    }
    return try await answer(call)
  }
}

/// A one-shot rendezvous, so an in-flight test needs no sleep.
actor UseSmileIDSampleTestGate {
  private var arrived = false
  private var opened = false
  private var awaitingArrival: [CheckedContinuation<Void, Never>] = []
  private var awaitingOpen: [CheckedContinuation<Void, Never>] = []

  func announceArrival() {
    arrived = true
    awaitingArrival.forEach { $0.resume() }
    awaitingArrival = []
  }

  func waitForArrival() async {
    guard !arrived else { return }
    await withCheckedContinuation { awaitingArrival.append($0) }
  }

  func open() {
    opened = true
    awaitingOpen.forEach { $0.resume() }
    awaitingOpen = []
  }

  func waitUntilOpen() async {
    guard !opened else { return }
    await withCheckedContinuation { awaitingOpen.append($0) }
  }
}
