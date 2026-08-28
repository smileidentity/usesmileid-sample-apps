import SwiftUI

/// Sentence-case headings, distinct from the all-caps ``UseSmileIDSampleSectionLabel``.
public struct UseSmileIDSampleSectionHeader: View {
  private let text: String
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(_ text: String, testId: String? = nil) {
    self.text = text
    self.testId = testId
  }

  public var body: some View {
    UseSmileIDSampleText(text, style: headerStyle)
      .foregroundColor(colors.foreground)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, SmileSpacing.spacingXs)
      .useSmileIDSampleTestId(testId)
  }

  private var headerStyle: SmileTextStyle {
    SmileTextStyle(
      family: UseSmileIDSampleTheme.type.textStyleHeadingSection.family,
      weight: smileSectionHeaderWeight,
      size: smileSectionHeaderSize,
      lineHeight: smileSectionHeaderLineHeight,
      tracking: 0
    )
  }
}
