import SwiftUI

public extension SmileTextStyle {
  /// The same style with one or two properties replaced.
  ///
  /// The label styles need it: the design's Type/Label is a point larger than
  /// `text-style.overline` and spaced, and both values are generated rather than written here.
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
      // A resize keeps the token's ratio unless the caller states a height, which the frame's own
      // heading metrics do — scaling those by ratio silently changes where wrapped text sits.
      lineHeight: lineHeight ?? (size ?? self.size) * (self.lineHeight / self.size),
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
