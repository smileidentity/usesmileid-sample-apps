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
    refusal(for: request) == nil
  }

  /// Why a request will not be recorded, or nil when it will be — named so a missing call can say
  /// which rule turned it away rather than leaving it to be guessed at.
  func refusal(for request: URLRequest) -> String? {
    guard isRecording else {
      return "not recording"
    }
    guard let url = request.url else {
      return "no url"
    }
    let absolute = url.absoluteString
    guard absolute.hasPrefix("http://") || absolute.hasPrefix("https://") else {
      return "scheme \(url.scheme ?? "none")"
    }
    if ignoredURLPrefixes.contains(where: { !$0.isEmpty && absolute.hasPrefix($0) }) {
      return "ignored prefix"
    }
    return nil
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
