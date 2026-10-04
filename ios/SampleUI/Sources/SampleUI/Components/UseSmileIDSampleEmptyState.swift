import SwiftUI

/// What a surface says when it has nothing to show; `supportingText` only where the reader can act.
public struct UseSmileIDSampleEmptyState: View {
  private let text: String
  private let supportingText: String?
  private let testId: String?
  private let onRetry: (() -> Void)?
  private let retryTestId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  /// `onRetry` only for a list that failed to load: retrying can change that answer, and nothing else here can.
  public init(
    text: String,
    supportingText: String? = nil,
    testId: String? = nil,
    onRetry: (() -> Void)? = nil,
    retryTestId: String? = nil
  ) {
    self.text = text
    self.supportingText = supportingText
    self.testId = testId
    self.onRetry = onRetry
    self.retryTestId = retryTestId
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
      if let onRetry {
        Button(action: onRetry) {
          UseSmileIDSampleText(UseSmileIDSampleStrings.commonRetry, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
            .foregroundColor(colors.textLink)
            .frame(minHeight: SmileSpacing.sizeControlMd)
        }
        .buttonStyle(.plain)
        .useSmileIDSampleTestId(retryTestId)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.space32)
  }
}
