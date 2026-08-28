import SwiftUI

/// Seat for the real Products screen, which U3 builds.
public struct ProductsScreen: View {
  public init() {}

  public var body: some View {
    Text("Products")
      .accessibilityIdentifier(UseSmileIDSampleTestIds.productsScreen)
  }
}
