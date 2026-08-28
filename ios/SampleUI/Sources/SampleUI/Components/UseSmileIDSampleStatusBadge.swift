import SwiftUI

/// A status pill in the design's soft tinted treatment: a pale fill with a dark same-hue label.
///
/// Two things a port gets wrong here. The label is Title case, NOT upper-cased — the same
/// 11/700 style IS upper-cased for date and section headers. And the pill takes `radius.control`,
/// not `radius.chip`.
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
