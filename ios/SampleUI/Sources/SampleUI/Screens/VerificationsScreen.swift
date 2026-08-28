import SwiftUI

/// Seat for the real Verifications screen, which U3 builds. It exists now so N1 has something to route to.
public struct VerificationsScreen: View {
  public init() {}

  public var body: some View {
    Text("Verifications")
      .accessibilityIdentifier(UseSmileIDSampleTestIds.verificationsScreen)
  }
}
