import SwiftUI

public extension SmileTextStyle {
  /// The same style with one or two properties replaced, which the label styles need against generated values.
  func with(
    size: CGFloat? = nil,
    tracking: CGFloat? = nil,
    weight: Int? = nil,
    lineHeight: CGFloat? = nil
  ) -> SmileTextStyle {
    SmileTextStyle(
      family: family,
      weight: weight ?? self.weight,
      size: size ?? self.size,
      // A resize keeps the token's ratio unless the caller states a height, as the frame's own heading metrics do.
      lineHeight: lineHeight ?? (size ?? self.size) * (self.lineHeight / self.size),
      tracking: tracking ?? self.tracking
    )
  }
}

public extension View {
  /// Attaches a `sample_*` id, on a leaf: an identifier on a container overrides every child's.
  @ViewBuilder
  func useSmileIDSampleTestId(_ id: String?) -> some View {
    if let id {
      accessibilityIdentifier(id)
    } else {
      self
    }
  }
}
