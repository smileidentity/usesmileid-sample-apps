import Foundation

/// What decides whether the loupe touches a request at all.
struct LoupeConfiguration: Equatable {
  var isRecording = false
  /// Prefixes rather than regular expressions, whose bad patterns crash the app being debugged.
  var ignoredURLPrefixes: [String] = []
  /// What the protocol tells the client to do with a response it forwards.
  var cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed

  /// Whether a request should be recorded, and so forwarded through the protocol.
  func shouldRecord(_ request: URLRequest) -> Bool {
    guard isRecording, let url = request.url else { return false }
    let absolute = url.absoluteString
    guard absolute.hasPrefix("http://") || absolute.hasPrefix("https://") else { return false }
    return !ignoredURLPrefixes.contains { !$0.isEmpty && absolute.hasPrefix($0) }
  }
}

/// The live configuration behind a lock, because `canInit` is nonisolated and cannot await.
final class LoupeConfigurationBox: @unchecked Sendable {
  private let lock = NSLock()
  private var storage = LoupeConfiguration()

  var current: LoupeConfiguration {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }

  func update(_ change: (inout LoupeConfiguration) -> Void) {
    lock.lock()
    defer { lock.unlock() }
    change(&storage)
  }
}
