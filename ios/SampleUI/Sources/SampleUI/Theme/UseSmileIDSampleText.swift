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
      .tracking(Self.tracking(style.tracking * scale, for: content))
      .underline(underlined)
      .lineSpacing(UseSmileIDSampleFonts.lineSpacing(style) * scale)
  }

  /// No tracking on joined scripts: spacing Arabic letters breaks the joins.
  static func tracking(_ tracking: CGFloat, for text: String) -> CGFloat {
    text.unicodeScalars.contains { scalar in joinedScripts.contains { $0.contains(scalar.value) } } ? 0 : tracking
  }

  /// Arabic and its supplements and presentation forms, where letters connect.
  private static let joinedScripts: [ClosedRange<UInt32>] = [
    0x0600...0x06ff, 0x0750...0x077f, 0x08a0...0x08ff, 0xfb50...0xfdff, 0xfe70...0xfeff
  ]
}
