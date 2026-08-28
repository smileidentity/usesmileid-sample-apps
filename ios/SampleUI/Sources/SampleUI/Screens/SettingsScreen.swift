import SwiftUI

/// Seat for the real Settings screen, which U3 builds.
public struct SettingsScreen: View {
  public init() {}

  public var body: some View {
    Text("Settings")
      .accessibilityIdentifier(UseSmileIDSampleTestIds.settingsScreen)
  }
}
