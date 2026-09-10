import SwiftUI

/// The platform switch, tinted from a semantic token: the design system has no switch contract, and only the on-track colour is host-settable on iOS.
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
