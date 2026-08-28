import SwiftUI

/// The platform switch, tinted from a semantic token.
///
/// Deliberately not hand-drawn: the design system has no switch contract
/// (`spec/components.json` → Switch), and the native control brings the right touch target, drag
/// behaviour and accessibility for free.
///
/// Only the on-track colour is host-settable on iOS, so the off and disabled tracks stay the
/// system's. The Compose twin maps those to `color.border`, which is the one place the two
/// platforms' switches visibly differ — and `color.border` is the token with the recorded
/// dark-mode defect, so matching it here would import a bright white pill, not fix one.
public struct UseSmileIDSampleSwitch: View {
  @Binding private var isOn: Bool
  private let enabled: Bool
  private let testId: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(isOn: Binding<Bool>, enabled: Bool = true, testId: String? = nil) {
    _isOn = isOn
    self.enabled = enabled
    self.testId = testId
  }

  public var body: some View {
    Toggle("", isOn: $isOn)
      .labelsHidden()
      .tint(colors.primary)
      .disabled(!enabled)
      .useSmileIDSampleTestId(testId)
  }
}
