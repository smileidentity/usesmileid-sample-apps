import SwiftUI

/// The all-caps group heading above a section; callers pass the text already cased, so nothing upper-cases per locale.
public struct UseSmileIDSampleSectionLabel: View {
  private let text: String
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(_ text: String, testId: String? = nil) {
    self.text = text
    self.testId = testId
  }

  public var body: some View {
    // The design's Type/Label, which text-style.overline sets a point small and solid.
    UseSmileIDSampleText(
      text,
      style: UseSmileIDSampleTheme.type.textStyleOverline
        .with(size: smileLabelSize, tracking: smileLabelTracking)
    )
    .foregroundColor(colors.textMuted)
    .useSmileIDSampleTestId(testId)
  }
}
