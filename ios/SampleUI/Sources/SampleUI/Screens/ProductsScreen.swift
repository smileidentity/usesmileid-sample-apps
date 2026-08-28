import SwiftUI

/// Seat for the real Products screen, which U3 builds. It exists now so N1 has something to route to.
public struct ProductsScreen: View {
  public init() {}

  public var body: some View {
    Text("Products")
      .accessibilityIdentifier(UseSmileIDSampleTestIds.productsScreen)
  }
}
