import SwiftUI

/// The full-width primary action. A minimum height so the label wraps rather than clips, and
/// loading refuses taps while keeping the enabled colours.
public struct UseSmileIDSampleButton: View {
  private let text: String
  private let action: () -> Void
  private let enabled: Bool
  private let loading: Bool
  private let testId: String?

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlLg
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    text: String,
    enabled: Bool = true,
    loading: Bool = false,
    testId: String? = nil,
    action: @escaping () -> Void
  ) {
    self.text = text
    self.enabled = enabled
    self.loading = loading
    self.testId = testId
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      // The label keeps its place while loading, so the button does not resize mid-tap.
      UseSmileIDSampleText(text, style: UseSmileIDSampleTheme.type.buttonFont)
        .multilineTextAlignment(.center)
        .padding(.vertical, SmileSpacing.space4)
        .opacity(loading ? 0 : 1)
        .overlay(loadingIndicator)
    }
    .buttonStyle(UseSmileIDSampleButtonStyle(enabled: enabled, loading: loading, minHeight: minHeight))
    .disabled(!enabled || loading)
    .useSmileIDSampleTestId(testId)
  }

  @ViewBuilder
  private var loadingIndicator: some View {
    if loading {
      // Tinted, because the default spinner is a mid grey that all but vanishes on the primary fill.
      ProgressView()
        .progressViewStyle(.circular)
        .tint(colors.button.primaryText)
    }
  }
}

private struct UseSmileIDSampleButtonStyle: ButtonStyle {
  let enabled: Bool
  let loading: Bool
  let minHeight: CGFloat

  @Environment(\.useSmileIDSampleColors) private var colors

  func makeBody(configuration: Configuration) -> some View {
    // Loading keeps the enabled colours: the action is running, not unavailable.
    let usesPrimary = enabled || loading
    configuration.label
      .foregroundColor(usesPrimary ? colors.button.primaryText : colors.button.disabledText)
      .frame(maxWidth: .infinity, minHeight: minHeight)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.pill, style: .continuous)
          .fill(usesPrimary ? colors.button.primaryBackground : colors.button.disabledBackground)
      )
      // The platform's own press feedback, rather than Android's ripple redrawn.
      .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
  }

  private static let pressedOpacity: Double = 0.8
}
