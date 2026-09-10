import SwiftUI

/// The scan target: one generated mark rather than a drawn reticle, so its proportions cannot drift.
public struct UseSmileIDSampleScanGlyph: View {
  private let size: CGFloat
  private let tint: Color?
  private let reticle: Bool

  @Environment(\.useSmileIDSampleColors) private var colors

  /// `tint` is the caller's, carrying the scanner's state; `reticle` is the design's hidden 45% state.
  public init(size: CGFloat = 279, tint: Color? = nil, reticle: Bool = false) {
    self.size = size
    self.tint = tint
    self.reticle = reticle
  }

  public var body: some View {
    UseSmileIDSampleIcon(Self.mark, tint: tint ?? colors.textTitle, size: size)
      .opacity(reticle ? Self.reticleOpacity : 1)
  }

  /// The design's own reticle opacity, which is what keeps it from competing with the preview.
  private static let reticleOpacity: Double = 0.45

  /// The generated mark carries 0.45 as a group opacity, so the parts are re-emitted opaque for the resting glyph.
  private static let mark = SmileIcon(
    width: SmileIcons.scanGlyph.width,
    height: SmileIcons.scanGlyph.height,
    minX: SmileIcons.scanGlyph.minX,
    minY: SmileIcons.scanGlyph.minY,
    parts: SmileIcons.scanGlyph.parts.map { SmileIconPart(stroke: $0.stroke, opacity: 1, build: $0.build) }
  )
}
