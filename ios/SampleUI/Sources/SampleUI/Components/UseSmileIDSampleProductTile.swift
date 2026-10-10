import SwiftUI

/// A product's hue tile with its icon: the job row's leading tile, and larger above the authentication user ID screen.
public struct UseSmileIDSampleProductTile: View {
  private let product: UseSmileIDSampleProduct
  private let side: CGFloat
  private let iconSize: CGFloat

  @Environment(\.useSmileIDSampleColors) private var colors

  /// `side` defaults to the job row's 36; the glyph is half the side unless `iconSize` fixes it, as the job row's 18 is.
  public init(_ product: UseSmileIDSampleProduct, side: CGFloat = 36, iconSize: CGFloat? = nil) {
    self.product = product
    self.side = side
    self.iconSize = iconSize ?? side / 2
  }

  public var body: some View {
    UseSmileIDSampleIcon(product.icon, tint: product.hue?.icon ?? colors.textMuted, size: iconSize)
      .frame(width: side, height: side)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.rowTile, style: .continuous)
          .fill(product.hue?.tile ?? colors.surfaceTile)
      )
  }
}
