import Foundation
import Observation

/// The loupe's front door: start recording, stop, and hold what the viewer draws.
@MainActor
@Observable
final class Loupe {
  /// One per app, because the protocol is registered process-wide.
  static let shared = Loupe()

  let store = LoupeStore()
  var isPresented = false
  private(set) var isRecording = false
  /// What recording is set to skip, shown on the settings screen.
  private(set) var ignoredURLPrefixes: [String] = []

  private init() {}

  /// Begins recording; starting twice registers the protocol once.
  func start(ignoring ignoredURLPrefixes: [String] = []) {
    guard !isRecording else { return }
    isRecording = true
    self.ignoredURLPrefixes = ignoredURLPrefixes
    let store = store
    LoupeURLProtocol.sink.install { record in
      Task { @MainActor in store.upsert(record) }
    }
    LoupeURLProtocol.configuration.update {
      $0.isRecording = true
      $0.ignoredURLPrefixes = ignoredURLPrefixes
    }
    URLProtocol.registerClass(LoupeURLProtocol.self)
    // Registration alone reaches only URLSession.shared; the SDK builds its own session
    LoupeSessionInstrumentation.install()
  }

  /// Stops recording, keeping the records already taken.
  func stop() {
    guard isRecording else { return }
    isRecording = false
    LoupeURLProtocol.configuration.update { $0.isRecording = false }
    URLProtocol.unregisterClass(LoupeURLProtocol.self)
  }

  /// Makes a session built from `configuration` visible, which registering alone cannot do.
  nonisolated static func instrument(_ configuration: URLSessionConfiguration) {
    var classes = configuration.protocolClasses ?? []
    guard !classes.contains(where: { $0 == LoupeURLProtocol.self }) else { return }
    classes.insert(LoupeURLProtocol.self, at: 0)
    configuration.protocolClasses = classes
  }
}
