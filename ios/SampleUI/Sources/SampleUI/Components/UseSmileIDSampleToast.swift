import SwiftUI

/// A snackbar with a message and an underlined action; the `sample_toast*` ids sit on the two leaves, or the container would override the action's.
public struct UseSmileIDSampleToast: View {
  private let message: String
  private let actionLabel: String?
  private let onAction: (() -> Void)?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 46
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(message: String, actionLabel: String? = nil, onAction: (() -> Void)? = nil) {
    self.message = message
    self.actionLabel = actionLabel
    self.onAction = onAction
  }

  public var body: some View {
    // Stacks once type grows: beside a wrapping message, the fixed-size action lands on top of it.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
          messageText
          action.frame(maxWidth: .infinity, alignment: .trailing)
        }
      } else {
        HStack(spacing: SmileSpacing.spacingSm) {
          messageText
          action
        }
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, Self.paddingY)
    .frame(minHeight: minHeight)
    .background(
      RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        .fill(colors.textTitle)
        .shadow(color: .black.opacity(Self.shadowOpacity), radius: Self.shadowRadius, y: Self.shadowY)
    )
  }

  private var messageText: some View {
    UseSmileIDSampleText(message, style: messageStyle)
      .foregroundColor(colors.background)
      .frame(maxWidth: .infinity, alignment: .leading)
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.toast)
  }

  @ViewBuilder
  private var action: some View {
    if let actionLabel, let onAction {
      Button(action: onAction) {
        UseSmileIDSampleText(actionLabel, style: actionStyle, underlined: true)
          .foregroundColor(colors.background)
          .fixedSize()
          // Widened, not squared off, and padded inside the minimum: outside it the message wraps.
          .padding(.horizontal, SmileSpacing.spacingXs)
          .frame(minWidth: SmileSpacing.sizeControlMd)
      }
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.toastUndo)
    }
  }

  private var messageStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.bannerTextFont.with(size: 13.5, weight: 500)
  }

  private var actionStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.linkFont.with(size: 14)
  }

  private static let radius: CGFloat = 12
  private static let paddingY: CGFloat = 13
  private static let shadowOpacity: Double = 0.25
  private static let shadowRadius: CGFloat = 15
  private static let shadowY: CGFloat = 10
}
