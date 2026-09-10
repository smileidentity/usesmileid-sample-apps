import SwiftUI

/// The scanner's state over the viewfinder, in one pill coloured from the feedback tokens; only a rejection offers an action.
public struct UseSmileIDSampleScanStatus: View {
  private let state: UseSmileIDSampleScanState
  private let onRetry: () -> Void

  @ScaledMetric(relativeTo: .body) private var retryHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(state: UseSmileIDSampleScanState, onRetry: @escaping () -> Void) {
    self.state = state
    self.onRetry = onRetry
  }

  public var body: some View {
    VStack(spacing: SmileSpacing.spacingXxs) {
      HStack(spacing: SmileSpacing.spacingXs) {
        if case .linked = state {
          UseSmileIDSampleIcon(SmileIcons.check, tint: foreground, size: SmileSpacing.sizeIconMd)
        }
        UseSmileIDSampleText(headline, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
          .multilineTextAlignment(.center)
      }
      if let detail {
        UseSmileIDSampleText(detail, style: UseSmileIDSampleTheme.type.textStyleCaption.with(size: 12.5))
          .multilineTextAlignment(.center)
      }
      // Only a rejection is actionable: everything else resolves itself in a beat.
      if case .rejected = state {
        Button(action: onRetry) {
          UseSmileIDSampleText("Try again", style: UseSmileIDSampleTheme.type.linkFont.with(weight: 700))
            .padding(.horizontal, SmileSpacing.spacingXs)
            .frame(minHeight: retryHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .foregroundColor(foreground)
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
    .background(RoundedRectangle(cornerRadius: SmileSpacing.radiusSurface, style: .continuous).fill(background))
  }

  private var background: Color {
    switch state {
    case .searching: colors.surface
    case .found: colors.infoFill
    case .linked: colors.successFill
    case .rejected: colors.errorFill
    }
  }

  private var foreground: Color {
    switch state {
    case .searching: colors.textTitle
    case .found: colors.onInfo
    case .linked: colors.onSuccess
    case .rejected: colors.onError
    }
  }

  private var headline: String {
    switch state {
    case .searching: "Point at a Smile token QR"
    case .found: "Token found"
    case .linked: "Session linked"
    case .rejected: "That is not a token"
    }
  }

  private var detail: String? {
    switch state {
    case .searching: nil
    case .found: "Reading it now"
    // The handle and the time it has left: never the token, which no surface here may show.
    case .linked(let handle, let remaining): "\(handle) \u{00B7} \(remaining) left"
    case .rejected(let reason): reason
    }
  }
}
