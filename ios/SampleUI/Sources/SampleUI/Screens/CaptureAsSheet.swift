import SwiftUI

/// How the SDK photographs the document; choosing Custom hands over to the custom-document sheet.
public struct CaptureAsSheet: View {
  private let selected: UseSmileIDSampleCaptureAs
  private let onSelect: (UseSmileIDSampleCaptureAs) -> Void

  public init(selected: UseSmileIDSampleCaptureAs, onSelect: @escaping (UseSmileIDSampleCaptureAs) -> Void) {
    self.selected = selected
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Capture as", testId: UseSmileIDSampleTestIds.captureAsSheet) {
      ForEach(UseSmileIDSampleCaptureAs.allCases, id: \.self) { option in
        UseSmileIDSampleOptionRow(
          label: option.label,
          selected: option == selected,
          testId: UseSmileIDSampleTestIds.captureAsOption(option.rawValue),
          onTap: { onSelect(option) }
        )
      }
    }
  }
}
