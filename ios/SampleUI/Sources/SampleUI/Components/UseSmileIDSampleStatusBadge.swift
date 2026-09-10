import SwiftUI

/// A soft tinted status pill: the label is Title case, not upper-cased like the same style's headers, and it takes `radius.control`.
public struct UseSmileIDSampleStatusBadge: View {
  private let status: UseSmileIDSampleStatus
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(status: UseSmileIDSampleStatus, testId: String? = nil) {
    self.status = status
    self.testId = testId
  }

  public var body: some View {
    UseSmileIDSampleText(
      status.label,
      style: UseSmileIDSampleTheme.type.textStyleOverline
        .with(size: smileLabelSize, tracking: smileLabelTracking)
    )
    .foregroundColor(fill.foreground)
    .padding(.horizontal, SmileSpacing.spacingXs)
    .padding(.vertical, SmileSpacing.space4)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.pill, style: .continuous)
        .fill(fill.background)
    )
    .useSmileIDSampleTestId(testId)
  }

  private var fill: (background: Color, foreground: Color) {
    let badge = colors.badge
    switch status {
    case .clear: return (badge.successBackground, badge.successText)
    case .attention: return (badge.warningBackground, badge.warningText)
    case .blocked: return (badge.errorBackground, badge.errorText)
    case .processing: return (badge.infoBackground, badge.infoText)
    }
  }
}
