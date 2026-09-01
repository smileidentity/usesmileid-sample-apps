import SwiftUI

/// What a surface says when it has nothing to show; `supportingText` only where the reader can act.
public struct UseSmileIDSampleEmptyState: View {
  private let text: String
  private let supportingText: String?
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(text: String, supportingText: String? = nil, testId: String? = nil) {
    self.text = text
    self.supportingText = supportingText
    self.testId = testId
  }

  public var body: some View {
    VStack(spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleText(text, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
        .foregroundColor(colors.textBody)
        .multilineTextAlignment(.center)
        .useSmileIDSampleTestId(testId)

      if let supportingText {
        UseSmileIDSampleText(supportingText, style: UseSmileIDSampleTheme.type.textStyleCaption)
          .foregroundColor(colors.textMuted)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.space32)
  }
}
