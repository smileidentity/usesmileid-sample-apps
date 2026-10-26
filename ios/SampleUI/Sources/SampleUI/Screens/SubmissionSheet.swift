import SwiftUI

/// config.skipApiSubmission's two values: submit the job, or hand the captured job back.
public struct SubmissionSheet: View {
  private let selected: UseSmileIDSampleSubmission
  private let onSelect: (UseSmileIDSampleSubmission) -> Void

  public init(selected: UseSmileIDSampleSubmission, onSelect: @escaping (UseSmileIDSampleSubmission) -> Void) {
    self.selected = selected
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: UseSmileIDSampleStrings.submissionTitle, testId: UseSmileIDSampleTestIds.submissionSheet) {
      ForEach(UseSmileIDSampleSubmission.allCases, id: \.self) { submission in
        UseSmileIDSampleOptionRow(
          label: submission.label,
          selected: submission == selected,
          testId: UseSmileIDSampleTestIds.submissionOption(submission.rawValue),
          onTap: { onSelect(submission) }
        )
      }
    }
  }
}
