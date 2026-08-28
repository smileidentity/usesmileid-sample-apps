import SwiftUI

public extension SmileTextStyle {
  /// The same style with one or two properties replaced.
  ///
  /// The label styles need it: the design's Type/Label is a point larger than
  /// `text-style.overline` and spaced, and both values are generated rather than written here.
  func with(size: CGFloat? = nil, tracking: CGFloat? = nil) -> SmileTextStyle {
    SmileTextStyle(
      family: family,
      weight: weight,
      size: size ?? self.size,
      // The token carries a total height, so a resize keeps the ratio rather than the gap.
      lineHeight: (size ?? self.size) * (lineHeight / self.size),
      tracking: tracking ?? self.tracking
    )
  }
}

public extension View {
  /// Attaches a `sample_*` id.
  ///
  /// Callers put this on a LEAF. An identifier on a container overrides every child's, so a
  /// component carrying two ids — the toast and its action — silently loses the inner one.
  @ViewBuilder
  func useSmileIDSampleTestId(_ id: String?) -> some View {
    if let id {
      accessibilityIdentifier(id)
    } else {
      self
    }
  }
}
