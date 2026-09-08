import SwiftUI

/// One verification: a product tile, its name, a secondary line of job id and time, and the status.
///
/// Select mode's checkbox is not a slot — the design puts it beside the card, and inside it cost the
/// title its width.
public struct UseSmileIDSampleJobRow: View {
  private let product: UseSmileIDSampleProduct
  private let jobId: String
  private let time: String
  private let status: UseSmileIDSampleStatus
  private let testId: String?
  private let statusTestId: String?
  private let onTap: (() -> Void)?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(
    product: UseSmileIDSampleProduct,
    jobId: String,
    time: String,
    status: UseSmileIDSampleStatus,
    testId: String? = nil,
    statusTestId: String? = nil,
    onTap: (() -> Void)? = nil
  ) {
    self.product = product
    self.jobId = jobId
    self.time = time
    self.status = status
    self.testId = testId
    // Derived from the row's own id, because one shared id would repeat on every row in the list.
    self.statusTestId = statusTestId ?? testId.map { "\($0)_status" }
    self.onTap = onTap
  }

  public var body: some View {
    if let onTap {
      Button(action: onTap) { card }.buttonStyle(.plain).useSmileIDSampleTestId(testId)
    } else {
      card.useSmileIDSampleTestId(testId)
    }
  }

  private var card: some View {
    // The badge stays inline at the design's scale and drops below once type grows; one layout
    // cannot do both, because the text column claims the whole line either way.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
          HStack(spacing: SmileSpacing.spacingSm) {
            tile
            text
          }
          UseSmileIDSampleStatusBadge(status: status, testId: statusTestId)
        }
      } else {
        HStack(spacing: SmileSpacing.spacingSm) {
          tile
          text
          UseSmileIDSampleStatusBadge(status: status, testId: statusTestId)
        }
      }
    }
    .padding(SmileSpacing.spacingSm)
    .frame(minHeight: minHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .fill(colors.card.background)
    )
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
    )
  }

  private var tile: some View {
    UseSmileIDSampleIcon(product.icon, tint: product.hue?.icon ?? colors.textMuted, size: SmileSpacing.sizeIconMd)
      .frame(width: tileSize, height: tileSize)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.rowTile, style: .continuous)
          .fill(product.hue?.tile ?? colors.surfaceTile)
      )
  }

  private var text: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleText(product.label, style: UseSmileIDSampleTheme.type.textStyleBodyStrong.with(size: 14))
        .foregroundColor(colors.textTitle)
      UseSmileIDSampleText("\(jobId)  ·  \(time)", style: UseSmileIDSampleTheme.type.textStyleCaption)
        .foregroundColor(colors.textMuted)
    }
    // One line each at the design's scale, as the design draws it; unlimited once the badge stacks.
    .lineLimit(sizeCategory.isAccessibilityCategory ? nil : 1)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
