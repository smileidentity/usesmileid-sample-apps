import SwiftUI

/// Seat for the real Settings screen, which U3 builds. It exists now so N1 has something to route to.
public struct SettingsScreen: View {
  public init() {}

  public var body: some View {
    Text("Settings")
      .accessibilityIdentifier(UseSmileIDSampleTestIds.settingsScreen)
  }
}
