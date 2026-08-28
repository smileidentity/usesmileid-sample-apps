import SwiftUI

/// The labelled rounded-hairline section card every detail and settings screen draws its rows on.
public struct UseSmileIDSampleSectionSurface<Content: View>: View {
  private let label: String?
  private let content: Content

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(label: String? = nil, @ViewBuilder content: () -> Content) {
    self.label = label
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
      if let label {
        UseSmileIDSampleSectionLabel(label)
      }
      VStack(spacing: 0) { content }
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
            .fill(colors.surface)
        )
        .overlay(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
            .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
        )
    }
  }
}

/// The rule between rows inside one section card.
public struct UseSmileIDSampleRowDivider: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  public init() {}

  public var body: some View {
    Rectangle()
      .fill(colors.cardStroke)
      .frame(height: smileCardStrokeWidth)
  }
}
