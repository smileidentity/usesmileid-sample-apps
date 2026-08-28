import SwiftUI

/// A snackbar: a dark bar with a message and an underlined action, spanning the width it is given.
///
/// Keeps the `sample_toast*` ids — the design node is named "toast", and renaming would churn
/// four apps. The ids sit on the two leaves rather than the bar, because an identifier on the
/// container would override the action's own.
public struct UseSmileIDSampleToast: View {
  private let message: String
  private let actionLabel: String?
  private let onAction: (() -> Void)?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 46
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(message: String, actionLabel: String? = nil, onAction: (() -> Void)? = nil) {
    self.message = message
    self.actionLabel = actionLabel
    self.onAction = onAction
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleText(message, style: messageStyle)
        .foregroundColor(colors.background)
        .frame(maxWidth: .infinity, alignment: .leading)
        .useSmileIDSampleTestId(UseSmileIDSampleTestIds.toast)

      if let actionLabel, let onAction {
        Button(action: onAction) {
          UseSmileIDSampleText(actionLabel, style: actionStyle, underlined: true)
            .foregroundColor(colors.background)
            .fixedSize()
            // Widened, not squared off: an action sized to the 44 tap minimum inflates the 46 bar.
            .frame(minWidth: SmileSpacing.sizeControlMd)
            .padding(.horizontal, SmileSpacing.spacingXs)
        }
        .useSmileIDSampleTestId(UseSmileIDSampleTestIds.toastUndo)
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

  private var messageStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.bannerTextFont.with(size: 13.5)
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
