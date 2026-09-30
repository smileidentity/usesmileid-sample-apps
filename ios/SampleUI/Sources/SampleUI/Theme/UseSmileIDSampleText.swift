import SwiftUI

/// Text drawn in one style from the token ramp, as a view rather than a `Text` extension so tracking goes on while the value is still a `Text`.
public struct UseSmileIDSampleText: View {
  private let content: String
  private let attributed: AttributedString?
  private let style: SmileTextStyle
  private let underlined: Bool

  /// The Dynamic Type factor, applied by hand to size, tracking and line spacing alike.
  @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

  /// `underlined` belongs here for the same reason tracking does: the decoration goes on while the value is still a `Text`.
  public init(_ content: String, style: SmileTextStyle, underlined: Bool = false) {
    self.content = content
    attributed = nil
    self.style = style
    self.underlined = underlined
  }

  /// For a run of text carrying its own attributes, such as a link.
  public init(_ attributed: AttributedString, style: SmileTextStyle) {
    content = String(attributed.characters)
    self.attributed = attributed
    self.style = style
    underlined = false
  }

  public var body: some View {
    (attributed.map { Text($0) } ?? Text(content))
      .font(UseSmileIDSampleFonts.font(style, scale: scale))
      .tracking(style.tracking * scale)
      .underline(underlined)
      .lineSpacing(UseSmileIDSampleFonts.lineSpacing(style) * scale)
  }
}
