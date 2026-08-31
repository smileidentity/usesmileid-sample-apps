import SwiftUI

/// Two columns of product cards, an odd count leaving its last cell empty.
///
/// Rows rather than a lazy grid, because the host screen already scrolls; each row takes its
/// tallest card's height.
public struct UseSmileIDSampleProductGrid<Item: View>: View {
  private let itemCount: Int
  private let item: (Int) -> Item

  public init(itemCount: Int, @ViewBuilder item: @escaping (Int) -> Item) {
    self.itemCount = itemCount
    self.item = item
  }

  public var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      ForEach(Array(stride(from: 0, to: itemCount, by: Self.columns)), id: \.self) { rowStart in
        HStack(alignment: .top, spacing: SmileSpacing.spacingSm) {
          ForEach(0..<Self.columns, id: \.self) { column in
            let index = rowStart + column
            if index < itemCount {
              item(index).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
              Color.clear.frame(maxWidth: .infinity)
            }
          }
        }
        .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private static var columns: Int {
    2
  }
}
