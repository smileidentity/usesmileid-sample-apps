import Combine
import SampleUI
import SwiftUI

/// What the shell holds on the app's behalf: the configuration every screen reads, and the profile
/// that names it. An `ObservableObject`, not `@Observable`, because the floor is iOS 15.
///
/// Writes live here rather than in a screen so a setting survives the screen that changed it.
final class UseSmileIDSampleAppState: ObservableObject {
  @Published var settings = UseSmileIDSampleSettings()
  @Published var organisation = "Kobo Bank"
  @Published var initials = "KB"

  /// The submitted rows. Nil is "not loaded yet", which the store U3 lands will resolve; until then
  /// a details link legitimately finds no row and the screen says which one it looked for.
  @Published var jobs: [UseSmileIDSampleJob]?

  /// The active session, which the products strip renders and the nav ring counts down.
  @Published var sessionId: String?
  @Published var sessionRemaining: String?
  @Published var sessionEnded = false

  var avatarColor: Color {
    useSmileIDSampleAvatarColor(profileIndex: 0)
  }

  /// Goes through the settings mutex, so agent mode and enhanced liveness cannot both end up on.
  func change(_ setting: UseSmileIDSampleSetting, to enabled: Bool) {
    settings = settings.with(setting, enabled)
  }

  var versionLabel: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    return "UseSmileID Sample \(version)"
  }
}
