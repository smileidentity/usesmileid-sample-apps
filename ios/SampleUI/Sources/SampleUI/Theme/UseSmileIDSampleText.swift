import SwiftUI

/// Text drawn in one style from the token ramp, as a view rather than a `Text` extension so tracking goes on while the value is still a `Text`.
public struct UseSmileIDSampleText: View {
  private let content: String
  private let style: SmileTextStyle
  private let underlined: Bool

  /// Tracking and line spacing are point values and need scaling by hand; only the font size follows Dynamic Type.
  @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

  /// `underlined` belongs here for the same reason tracking does: the decoration goes on while the value is still a `Text`.
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
