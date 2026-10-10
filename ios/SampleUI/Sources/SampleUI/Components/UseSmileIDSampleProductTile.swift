import SwiftUI

/// A product's hue tile with its icon: the job row's leading tile, and larger above the authentication user ID screen.
public struct UseSmileIDSampleProductTile: View {
  private let product: UseSmileIDSampleProduct
  private let side: CGFloat

  @Environment(\.useSmileIDSampleColors) private var colors

  /// `side` defaults to the job row's 36, whose glyph is the board's 18; a larger tile scales the glyph with it.
  public init(_ product: UseSmileIDSampleProduct, side: CGFloat = 36) {
    self.product = product
    self.side = side
  }

  public var body: some View {
    UseSmileIDSampleIcon(product.icon, tint: product.hue?.icon ?? colors.textMuted, size: side / 2)
      .frame(width: side, height: side)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.rowTile, style: .continuous)
          .fill(product.hue?.tile ?? colors.surfaceTile)
      )
  }
}
