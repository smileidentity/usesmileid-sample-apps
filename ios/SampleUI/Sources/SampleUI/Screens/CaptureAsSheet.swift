import SwiftUI

/// How the SDK photographs the document: Match document first, then the overrides; Generic document hands over to its sheet.
public struct CaptureAsSheet: View {
  private let selected: UseSmileIDSampleCaptureAs?
  private let matched: UseSmileIDSampleResolvedCaptureAs
  private let onSelect: (UseSmileIDSampleCaptureAs?) -> Void

  /// `selected` nil is Match document; `matched` is what it resolves to for the chosen row, which its row names.
  public init(
    selected: UseSmileIDSampleCaptureAs?,
    matched: UseSmileIDSampleResolvedCaptureAs,
    onSelect: @escaping (UseSmileIDSampleCaptureAs?) -> Void
  ) {
    self.selected = selected
    self.matched = matched
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Capture as", testId: UseSmileIDSampleTestIds.captureAsSheet) {
      UseSmileIDSampleOptionRow(
        label: matched.matchRowLabel,
        selected: selected == nil,
        testId: UseSmileIDSampleTestIds.captureAsOption(UseSmileIDSampleCaptureAs.matchDocumentId),
        onTap: { onSelect(nil) }
      )
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
