import SwiftUI

/// The three appearances; System's label names `deviceDark`, the device's own theme.
public struct AppearanceSheet: View {
  private let selected: UseSmileIDSampleAppearance
  private let deviceDark: Bool
  private let onSelect: (UseSmileIDSampleAppearance) -> Void

  public init(
    selected: UseSmileIDSampleAppearance,
    deviceDark: Bool,
    onSelect: @escaping (UseSmileIDSampleAppearance) -> Void
  ) {
    self.selected = selected
    self.deviceDark = deviceDark
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: UseSmileIDSampleStrings.appearanceTitle, testId: UseSmileIDSampleTestIds.appearanceSheet) {
      ForEach(UseSmileIDSampleAppearance.allCases, id: \.self) { appearance in
        UseSmileIDSampleOptionRow(
          label: appearance.label(deviceDark: deviceDark),
          selected: appearance == selected,
          testId: UseSmileIDSampleTestIds.appearanceOption(appearance.rawValue),
          onTap: { onSelect(appearance) }
        )
      }
    }
  }
}
