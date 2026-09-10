import SwiftUI

/// One generated mark, drawn at `size` and tinted by the caller; decorative by default, the enclosing control carrying the label.
public struct UseSmileIDSampleIcon: View {
  private let icon: SmileIcon
  private let tint: Color
  private let size: CGFloat

  public init(_ icon: SmileIcon, tint: Color, size: CGFloat = SmileSpacing.sizeIconMd) {
    self.icon = icon
    self.tint = tint
    self.size = size
  }

  public var body: some View {
    ZStack {
      ForEach(Array(icon.parts.enumerated()), id: \.offset) { _, part in
        let shape = SmileIconShape(icon: icon, part: part)
        switch part.stroke {
        case .fill:
          shape.fill(tint).opacity(part.opacity)
        case .stroke(let width, let round):
          shape.stroke(
            tint,
            style: StrokeStyle(
              // Scaled with the mark, or a 17pt icon drawn at 40 keeps a hairline stroke.
              lineWidth: width * scale,
              lineCap: round ? .round : .butt,
              lineJoin: round ? .round : .miter
            )
          )
          .opacity(part.opacity)
        }
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  /// The mark is square in practice; the smaller ratio keeps a non-square one inside its frame.
  private var scale: CGFloat {
    min(size / icon.width, size / icon.height)
  }
}

private struct SmileIconShape: Shape {
  let icon: SmileIcon
  let part: SmileIconPart

  func path(in rect: CGRect) -> Path {
    var path = Path()
    part.build(&path)
    let scale = min(rect.width / icon.width, rect.height / icon.height)
    // The viewBox origin is not always zero — the Material Symbols marks start at y = -960.
    return path.applying(
      CGAffineTransform(translationX: -icon.minX, y: -icon.minY).concatenating(
        CGAffineTransform(scaleX: scale, y: scale)
      )
    )
  }
}
