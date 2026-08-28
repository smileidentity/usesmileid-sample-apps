import SwiftUI

/// A status dot and the environment name on a pale fill. Display-only, and not fixed-width, because
/// Production is wider than Sandbox.
public struct UseSmileIDSampleProfileEnvChip: View {
  private let environment: UseSmileIDSampleEnvironment

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space32
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(environment: UseSmileIDSampleEnvironment) {
    self.environment = environment
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      Circle()
        .fill(environment == .sandbox ? colors.warningFill : colors.successFill)
        .frame(width: SmileSpacing.spacingXs, height: SmileSpacing.spacingXs)
      UseSmileIDSampleText(environment.label, style: UseSmileIDSampleTheme.type.textStyleCaption)
        .foregroundColor(colors.textBody)
        .useSmileIDSampleTestId(UseSmileIDSampleTestIds.envChip)
    }
    .padding(.horizontal, SmileSpacing.spacingSm)
    .padding(.vertical, SmileSpacing.spacingXxs)
    .frame(minHeight: minHeight)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.chip, style: .continuous)
        .fill(colors.surfaceAlt)
    )
  }
}
