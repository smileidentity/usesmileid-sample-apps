import SwiftUI

/// DocumentCaptureConfig.captureMode's three values; the fallback keeps the SDK's 10 seconds.
public struct CaptureModeSheet: View {
  private let selected: UseSmileIDSampleCaptureMode
  private let onSelect: (UseSmileIDSampleCaptureMode) -> Void

  public init(selected: UseSmileIDSampleCaptureMode, onSelect: @escaping (UseSmileIDSampleCaptureMode) -> Void) {
    self.selected = selected
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Capture mode", testId: UseSmileIDSampleTestIds.captureModeSheet) {
      ForEach(UseSmileIDSampleCaptureMode.allCases, id: \.self) { mode in
        UseSmileIDSampleOptionRow(
          label: mode.label,
          selected: mode == selected,
          testId: UseSmileIDSampleTestIds.captureModeOption(mode.rawValue),
          onTap: { onSelect(mode) }
        )
      }
    }
  }
}
