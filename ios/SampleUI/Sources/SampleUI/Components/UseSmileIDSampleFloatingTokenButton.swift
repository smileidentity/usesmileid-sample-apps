import SwiftUI

/// Reaches the token session from inside a form, where the nav bar's token affordance is covered.
public struct UseSmileIDSampleFloatingTokenButton: View {
  private let action: () -> Void

  @ScaledMetric(relativeTo: .body) private var size: CGFloat = SmileSpacing.space48
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      UseSmileIDSampleIcon(SmileIcons.tokenScan, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
        .frame(width: size, height: size)
        // White with a border, like the nav bar's token control — not a primary-filled FAB.
        .background(Circle().fill(colors.surface).shadow(radius: SmileSpacing.space4 / 2))
        .overlay(Circle().strokeBorder(colors.border, lineWidth: smileCardStrokeWidth))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Token session")
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.tokenFloat)
  }
}
