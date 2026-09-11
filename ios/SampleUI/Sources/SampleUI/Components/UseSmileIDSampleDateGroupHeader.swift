import SwiftUI

/// The date separator in the verifications list; both halves arrive formatted, being locale-dependent.
public struct UseSmileIDSampleDateGroupHeader: View {
  private let relative: String
  private let absolute: String
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(relative: String, absolute: String, testId: String? = nil) {
    self.relative = relative
    self.absolute = absolute
    self.testId = testId
  }

  public var body: some View {
    // Two spaces either side of the dot, as the design sets it; with no relative word the date stands alone.
    UseSmileIDSampleText(
      relative.isEmpty ? absolute : "\(relative)  ·  \(absolute)",
      style: UseSmileIDSampleTheme.type.textStyleOverline.with(size: smileLabelSize, tracking: smileLabelTracking)
    )
    .foregroundColor(colors.textMuted)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, SmileSpacing.spacingXs)
    .useSmileIDSampleTestId(testId)
  }
}
