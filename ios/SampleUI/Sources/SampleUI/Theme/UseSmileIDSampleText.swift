import SwiftUI

/// Text drawn in one style from the token ramp.
///
/// A view rather than a `Text` extension because tracking has to be applied while the value is
/// still a `Text`: `View.tracking(_:)` is iOS 16, and this package's floor is iOS 15.
public struct UseSmileIDSampleText: View {
  private let content: String
  private let style: SmileTextStyle
  private let underlined: Bool

  /// Tracking and line spacing are point values, so they need scaling by hand — only the font size
  /// follows Dynamic Type on its own.
  @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

  /// `underlined` belongs here for the same reason tracking does: `View.underline()` is iOS 16, so
  /// the decoration has to go on while the value is still a `Text`.
  public init(_ content: String, style: SmileTextStyle, underlined: Bool = false) {
    self.content = content
    self.style = style
    self.underlined = underlined
  }

  public var body: some View {
    Text(content)
      .font(UseSmileIDSampleFonts.font(style))
      .tracking(style.tracking * scale)
      .underline(underlined)
      .lineSpacing(style.lineSpacing * scale)
  }
}
