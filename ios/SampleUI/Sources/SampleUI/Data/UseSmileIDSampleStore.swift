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

/// Everything the sample persists: the settings the SDK flow is composed from, the profiles, and the token session. Each record has its own home — the token is a credential, the switches are not.
public final class UseSmileIDSampleStore {
  private let storage: UseSmileIDSampleRecordStorage
  private let settingsStorage: UseSmileIDSampleSettingsStorage

  /// The six switches, read once at construction: a value passed at launch outranks the written one for the life of the process, so re-reading would answer a write with the launch's value.
  public private(set) var settings: UseSmileIDSampleSettings

  public init(
    storage: UseSmileIDSampleRecordStorage = UseSmileIDSampleKeychainStorage(),
    settingsStorage: UseSmileIDSampleSettingsStorage = UseSmileIDSampleDefaultsStorage()
  ) {
    self.storage = storage
    self.settingsStorage = settingsStorage
    let defaults = UseSmileIDSampleSettings()
    // Absent rows are today's defaults, so a default the design changes still reaches a device that has used the screen.
    settings = UseSmileIDSampleSettings(
      enhancedSmartSelfie: settingsStorage.flag(.enhancedSmartSelfie) ?? defaults.enhancedSmartSelfie,
      agentMode: settingsStorage.flag(.agentMode) ?? defaults.agentMode,
      darkMode: settingsStorage.flag(.darkMode) ?? defaults.darkMode,
      consentStep: settingsStorage.flag(.consentStep) ?? defaults.consentStep,
      instructionsStep: settingsStorage.flag(.instructionsStep) ?? defaults.instructionsStep,
      previewStep: settingsStorage.flag(.previewStep) ?? defaults.previewStep
    ).normalised()
  }

  /// Writes through the settings model, so the capture mutex moves the other row in the same edit; returns the result, which is also what the store now reads.
  @discardableResult
  public func setSetting(_ setting: UseSmileIDSampleSetting, _ enabled: Bool) -> UseSmileIDSampleSettings {
    let current = settings
    let updated = current.with(setting, enabled)
    // Only what moved: writing all six would freeze today's defaults onto the device.
    for row in UseSmileIDSampleSetting.allCases where updated[row] != current[row] {
      settingsStorage.setFlag(row, updated[row])
    }
    settings = updated
    return updated
  }

  /// A missing or unreadable record is no profiles, so an install that never stored one reads as a first launch.
  public var profiles: UseSmileIDSampleProfiles {
    UseSmileIDSampleProfilesCodec.decode(settingsStorage.data(Self.profilesKey))
  }

  /// The whole record in one write, so the list and the active id can never come from different edits.
  public func setProfiles(_ profiles: UseSmileIDSampleProfiles) {
    guard let data = UseSmileIDSampleProfilesCodec.encode(profiles) else { return }
    settingsStorage.setData(Self.profilesKey, data)
  }

  /// The Android store's key, so a record reads the same in both.
  static let profilesKey = "sample_profiles"

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

public extension UseSmileIDSampleSetting {
  /// The Android store's own key name, so a row reads the same in both and automation can seed one at launch.
  var storageKey: String {
    switch self {
    case .enhancedSmartSelfie: "enhanced_smart_selfie"
    case .agentMode: "agent_mode"
    case .darkMode: "dark_mode"
    case .consentStep: "consent_step"
    case .instructionsStep: "instructions_step"
    case .previewStep: "preview_step"
    }
  }
}

/// Where the six switches live: `UserDefaults` in an app, memory in a test. Read per row, since an absent row is today's default rather than `false`.
public protocol UseSmileIDSampleSettingsStorage: AnyObject {
  func flag(_ key: String) -> Bool?
  func setFlag(_ key: String, _ value: Bool)
  func data(_ key: String) -> Data?
  func setData(_ key: String, _ value: Data)
}

public extension UseSmileIDSampleSettingsStorage {
  /// By row rather than by key, so a caller never spells one.
  func flag(_ setting: UseSmileIDSampleSetting) -> Bool? {
    flag(setting.storageKey)
  }

  func setFlag(_ setting: UseSmileIDSampleSetting, _ value: Bool) {
    setFlag(setting.storageKey, value)
  }
}

/// The switches, in the app's own defaults: not credentials, and the app container is what an uninstall clears.
public final class UseSmileIDSampleDefaultsStorage: UseSmileIDSampleSettingsStorage {
  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func flag(_ key: String) -> Bool? {
    defaults.object(forKey: key) == nil ? nil : defaults.bool(forKey: key)
  }

  public func setFlag(_ key: String, _ value: Bool) {
    defaults.set(value, forKey: key)
  }

  /// Never from a launch argument: a `<hex>` argument arrives as data, and fixtures reach a launch only through `seedProfiles`.
  public func data(_ key: String) -> Data? {
    if UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)[key] != nil {
      return nil
    }
    return defaults.data(forKey: key)
  }

  public func setData(_ key: String, _ value: Data) {
    defaults.set(value, forKey: key)
  }
}

/// The switches held for one process, for tests and for a host that wants no persistence.
public final class UseSmileIDSampleMemorySettingsStorage: UseSmileIDSampleSettingsStorage {
  private var flags: [String: Bool] = [:]
  private var blobs: [String: Data] = [:]

  public init() {}

  public func flag(_ key: String) -> Bool? {
    flags[key]
  }

  public func setFlag(_ key: String, _ value: Bool) {
    flags[key] = value
  }

  public func data(_ key: String) -> Data? {
    blobs[key]
  }

  public func setData(_ key: String, _ value: Data) {
    blobs[key] = value
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
