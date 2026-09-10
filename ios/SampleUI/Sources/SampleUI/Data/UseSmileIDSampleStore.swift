import Foundation
import Security

/// A session that has run out, remembered without its credential.
public struct UseSmileIDSampleEndedSession: Equatable, Sendable {
  public let id: String
  public let endedAt: Date

  public init(id: String, endedAt: Date) {
    self.id = id
    self.endedAt = endedAt
  }
}

/// At most one half is ever set: retiring replaces the token with its marker in a single write.
public struct UseSmileIDSampleSessionRecord: Equatable, Sendable {
  public var live: UseSmileIDSampleTokenSession?
  public var ended: UseSmileIDSampleEndedSession?

  public init(live: UseSmileIDSampleTokenSession? = nil, ended: UseSmileIDSampleEndedSession? = nil) {
    self.live = live
    self.ended = ended
  }
}

/// Where the record's bytes live: the Keychain in an app, memory in a test.
public protocol UseSmileIDSampleRecordStorage: AnyObject {
  func read() -> Data?
  /// Nil deletes; the whole record is replaced in one write, never patched.
  func write(_ data: Data?)
}

/// The token session, in the Keychain. The token is the whole record — handle, deadline and bindings decode from it — so nothing can disagree with it.
public final class UseSmileIDSampleStore {
  private let storage: UseSmileIDSampleRecordStorage

  public init(storage: UseSmileIDSampleRecordStorage = UseSmileIDSampleKeychainStorage()) {
    self.storage = storage
  }

  /// Both halves from one read, so the UI can never hold the token from one write and the marker from the next.
  public var session: UseSmileIDSampleSessionRecord {
    guard let data = storage.read(), let stored = try? JSONDecoder().decode(StoredRecord.self, from: data) else {
      return UseSmileIDSampleSessionRecord()
    }
    return UseSmileIDSampleSessionRecord(
      live: stored.token.flatMap(UseSmileIDSampleTokenDecoder.session),
      ended: stored.endedId.map {
        UseSmileIDSampleEndedSession(id: $0, endedAt: Date(timeIntervalSince1970: Double(stored.endedAt ?? 0) / 1000))
      }
    )
  }

  /// Takes the session rather than the raw token, so only a decoded one can ever be linked. A new session is not an ended one.
  public func linkTokenSession(_ session: UseSmileIDSampleTokenSession) {
    write(StoredRecord(token: session.token))
  }

  /// Sign out: no ended marker, which would send the next run to the scanner.
  public func clearTokenSession() {
    storage.write(nil)
  }

  /// Deletes the credential at its deadline, keeping only that the session ended.
  public func retireTokenSession(_ session: UseSmileIDSampleTokenSession) {
    write(StoredRecord(endedId: session.id, endedAt: Int64(session.expiresAt.timeIntervalSince1970 * 1000)))
  }

  /// Nil is delete, so a record that fails to encode leaves the stored one untouched rather than wiping it.
  private func write(_ record: StoredRecord) {
    guard let data = try? JSONEncoder().encode(record) else { return }
    storage.write(data)
  }

  /// The Android store's three keys, so a record reads the same in both.
  private struct StoredRecord: Codable {
    var token: String?
    var endedId: String?
    var endedAt: Int64?

    enum CodingKeys: String, CodingKey {
      case token = "token_session_token"
      case endedId = "ended_session_id"
      case endedAt = "ended_session_at"
    }
  }
}

/// One generic-password item, unlocked-only; the service is not an application id, so it stays identity-agnostic.
public final class UseSmileIDSampleKeychainStorage: UseSmileIDSampleRecordStorage {
  private let service: String

  public init(service: String = "usesmileid_sample") {
    self.service = service
  }

  public func read() -> Data? {
    var query = item
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
    return result as? Data
  }

  public func write(_ data: Data?) {
    guard let data else {
      SecItemDelete(item as CFDictionary)
      return
    }
    let update = [kSecValueData as String: data]
    if SecItemUpdate(item as CFDictionary, update as CFDictionary) == errSecItemNotFound {
      var add = item
      add[kSecValueData as String] = data
      add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      SecItemAdd(add as CFDictionary, nil)
    }
  }

  private var item: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: "token_session"
    ]
  }
}

/// A record held for one process, for tests and for a host that wants no persistence.
public final class UseSmileIDSampleMemoryStorage: UseSmileIDSampleRecordStorage {
  private var data: Data?

  public init() {}

  public func read() -> Data? {
    data
  }

  public func write(_ data: Data?) {
    self.data = data
  }
}
