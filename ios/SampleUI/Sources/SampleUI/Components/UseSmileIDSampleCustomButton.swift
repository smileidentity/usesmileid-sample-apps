public import UseSmileID
import SwiftUI

/// The sample's own continue button, drawn by the SDK in its continue slots while Custom continue is on.
public struct UseSmileIDSampleCustomContinueButton: View {
  private let enabled: Bool
  private let action: () -> Void

  public init(enabled: Bool = true, action: @escaping () -> Void) {
    self.enabled = enabled
    self.action = action
  }

  public var body: some View {
    UseSmileIDSampleButton(
      text: useSmileIDSampleCustomContinueLabel,
      enabled: enabled,
      testId: UseSmileIDSampleTestIds.customContinue,
      action: action
    )
  }
}

/// The sample's own cancel button, for the SDK's cancel slots: the continue button's outlined twin.
public struct UseSmileIDSampleCustomCancelButton: View {
  private let enabled: Bool
  private let action: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlLg
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(enabled: Bool = true, action: @escaping () -> Void) {
    self.enabled = enabled
    self.action = action
  }

  public var body: some View {
    let colour = enabled ? colors.button.primaryBackground : colors.button.disabledText
    Button(action: action) {
      UseSmileIDSampleText(useSmileIDSampleCustomCancelLabel, style: UseSmileIDSampleTheme.type.buttonFont)
        .multilineTextAlignment(.center)
        .padding(.vertical, SmileSpacing.space4)
        .foregroundColor(colour)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .overlay(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.pill, style: .continuous)
            .strokeBorder(enabled ? colour : colors.button.disabledBackground, lineWidth: SmileSpacing.borderWidthThin)
        )
        .contentShape(RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.pill, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.customCancel)
  }
}

/// The continue slots' content; the SDK's scope decides what the tap does and when it is allowed.
@MainActor public let useSmileIDSampleCustomContinueSlot: (ButtonSlotScope) -> AnyView = { scope in
  AnyView(UseSmileIDSampleCustomContinueButton(enabled: scope.enabled, action: scope.onClick))
}

/// The cancel slots' content.
@MainActor public let useSmileIDSampleCustomCancelSlot: (ButtonSlotScope) -> AnyView = { scope in
  AnyView(UseSmileIDSampleCustomCancelButton(enabled: scope.enabled, action: scope.onClick))
}

let useSmileIDSampleCustomContinueLabel = "Custom continue"
let useSmileIDSampleCustomCancelLabel = "Custom cancel"
